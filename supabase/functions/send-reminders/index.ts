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
    // 1. Unsent Bookings fetch karo (Aaj aur aage ki)
    const { data: bookings, error } = await supabase
      .from('bookings')
      .select('*, clients(email, full_name), user_profiles(email, full_name)')
      .eq('reminder_sent', false)
      .gte('start_date', new Date().toISOString().split('T')[0]) 
    
    if (error) throw error;

    const updates = [];
    let sentCount = 0;

    // --- TIMEZONE SETTING (Pakistan = 5) ---
    // Agar future mein kisi aur country ke liye banana ho toh ye 5 change karlena
    const TIMEZONE_OFFSET_HOURS = 5; 

    for (const booking of bookings || []) {
      
      // A. Booking ka Time (Database se)
      const bookingTime = new Date(`${booking.start_date}T${booking.start_time}`);

      // B. Server ka Time (UTC) ko Pakistan Time banao
      const nowUTC = new Date();
      const nowPKT = new Date(nowUTC.getTime() + (TIMEZONE_OFFSET_HOURS * 60 * 60 * 1000));

      // C. Difference nikalo (Minutes mein)
      const diffMs = bookingTime.getTime() - nowPKT.getTime();
      const diffMins = diffMs / 60000;

      // Debugging ke liye Logs (Console mein dikhega)
      console.log(`Booking: ${booking.id} | Diff: ${diffMins.toFixed(0)} mins`);

      // D. Check: Agar booking 30 se 90 mins ke beech hai (Matlab ~1 hour left)
      if (diffMins > 30 && diffMins <= 90) {
        
        console.log(`>>> Sending Reminder for Booking ${booking.id}`);

        const mailOptions = {
          from: `"Sitter Pro App" <${SMTP_USER}>`,
          subject: "⏰ Appointment Reminder: 1 Hour to go!",
          html: `
            <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 8px;">
              <h2 style="color: #333;">Upcoming Appointment</h2>
              <p>Hello,</p>
              <p>This is a reminder that your booking starts in about an hour.</p>
              <hr/>
              <p><strong>Date:</strong> ${booking.start_date}</p>
              <p><strong>Time:</strong> ${booking.start_time}</p>
              <p><strong>Address:</strong> ${booking.address}</p>
              <hr/>
              <p style="font-size: 12px; color: #888;">Sitter Pro Automated System</p>
            </div>
          `
        };

        // Client ko Email
        if (booking.clients?.email) {
          await transporter.sendMail({ ...mailOptions, to: booking.clients.email });
        }
        
        // Sitter ko Email
        if (booking.user_profiles?.email) {
           await transporter.sendMail({ ...mailOptions, to: booking.user_profiles.email });
        }

        // List mein daal do taaki baad mein status update karein
        updates.push(booking.id);
        sentCount++;
      }
    }

    // 2. Database Update: Jin ko mail chala gaya, unhe tick kar do
    if (updates.length > 0) {
      await supabase
        .from('bookings')
        .update({ reminder_sent: true })
        .in('id', updates);
      
      console.log(`Updated ${updates.length} bookings as sent.`);
    }

    return new Response(JSON.stringify({ success: true, sent: sentCount }), { 
      headers: { 'Content-Type': 'application/json' } 
    })

  } catch (error) {
    console.error("Error:", error.message)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})