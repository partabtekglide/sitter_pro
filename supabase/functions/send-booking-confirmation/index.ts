import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import nodemailer from "npm:nodemailer@6.9.7"; 

const SMTP_USER = Deno.env.get('SMTP_USER')
const SMTP_PASS = Deno.env.get('SMTP_PASS')
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!)

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: SMTP_USER,
    pass: SMTP_PASS,
  },
});

serve(async (req) => {
  try {
    const payload = await req.json()
    // Webhook se jo data aata hai wo 'record' ke andar hota hai
    const booking = payload.record 

    console.log("New booking received:", booking.id);

    // 1. Client ka Email nikalo
    const { data: clientData, error } = await supabase
      .from('clients')
      .select('email, full_name')
      .eq('id', booking.client_id)
      .single()

    if (error || !clientData?.email) {
      console.log("Client email not found or fetch error");
      return new Response("No email found", { status: 200 })
    }

    // 2. Sitter ka Naam nikalo
    const { data: sitterData } = await supabase
      .from('user_profiles')
      .select('full_name')
      .eq('id', booking.sitter_id)
      .single()

    // 3. Email Send karo
    await transporter.sendMail({
      from: `"Sitter Pro App" <${SMTP_USER}>`,
      to: clientData.email,
      subject: "Booking Confirmed! ✅",
      html: `
        <div style="font-family: sans-serif; padding: 20px;">
          <h2>Hello ${clientData.full_name},</h2>
          <p>Your booking request has been registered!</p>
          <hr/>
          <p><strong>Sitter:</strong> ${sitterData?.full_name || 'The Sitter'}</p>
          <p><strong>Date:</strong> ${booking.start_date}</p>
          <p><strong>Time:</strong> ${booking.start_time}</p>
          <p><strong>Address:</strong> ${booking.address}</p>
          <hr/>
          <p>Thanks,<br/>Sitter Pro Team</p>
        </div>
      `,
    });

    console.log("Email sent successfully!");
    
    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error("Error:", error.message)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})