// supabase/functions/send-client-message/index.ts
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
  auth: { user: SMTP_USER, pass: SMTP_PASS },
});

serve(async (req) => {
  try {
    const payload = await req.json()
    const record = payload.record // Ye 'communications' table ka data hai

    console.log("New Message ID:", record.id);

    // 1. Client ka Email nikalo (receiver_id yahan client_id hai)
    const { data: clientData, error: clientError } = await supabase
      .from('clients')
      .select('email, full_name')
      .eq('id', record.receiver_id) // Hum receiver_id mein client_id save karenge
      .single()

    if (clientError || !clientData?.email) {
      console.log("Client email not found, stopping.");
      return new Response("No Email", { status: 200 })
    }

    // 2. Sitter (Sender) ka Naam nikalo
    const { data: sitterData } = await supabase
      .from('user_profiles')
      .select('full_name')
      .eq('id', record.sender_id)
      .single()

    // 3. Email Bhejo
    await transporter.sendMail({
      from: `"Sitter Pro Message" <${SMTP_USER}>`,
      to: clientData.email,
      subject: `New Message from ${sitterData?.full_name || 'Sitter'} 💬`,
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; background-color: #f9f9f9; border-radius: 10px;">
          <h3 style="color: #333;">New Message</h3>
          <p><strong>From:</strong> ${sitterData?.full_name}</p>
          <div style="background-color: white; padding: 15px; border-left: 4px solid #4CAF50; margin: 20px 0;">
            <p style="font-size: 16px; color: #555;">${record.content}</p>
          </div>
          <p style="font-size: 12px; color: #999;">Do not reply to this email directly.</p>
        </div>
      `,
    });

    console.log("Email sent successfully!");
    return new Response(JSON.stringify({ success: true }), { headers: { 'Content-Type': 'application/json' } })

  } catch (error) {
    console.error(error)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})