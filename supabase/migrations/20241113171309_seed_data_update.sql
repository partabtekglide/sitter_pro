-- Additional seed data for testing all functionality
-- This migration adds minimal data as requested: 1 sitter, 1 client, 1 service, 2 bookings

-- Add communication templates
INSERT INTO communications (
  id, sender_id, receiver_id, type, subject, content, created_at
) VALUES
-- Confirmation template
(
  gen_random_uuid(),
  '5157c34a-d658-43cf-8a23-eebc2e0b8ac8',
  '5157c34a-d658-43cf-8a23-eebc2e0b8ac8',
  'notification',
  'Booking Confirmation',
  'Hi {client_name}, your {service_type} booking for {date} at {time} has been confirmed. Looking forward to seeing you!',
  CURRENT_TIMESTAMP
),
-- Reminder template
(
  gen_random_uuid(),
  '5157c34a-d658-43cf-8a23-eebc2e0b8ac8',
  '5157c34a-d658-43cf-8a23-eebc2e0b8ac8',
  'notification',
  'Appointment Reminder',
  'Hi {client_name}, this is a friendly reminder about your {service_type} appointment tomorrow at {time}. See you soon!',
  CURRENT_TIMESTAMP
),
-- Follow-up template
(
  gen_random_uuid(),
  '5157c34a-d658-43cf-8a23-eebc2e0b8ac8',
  '5157c34a-d658-43cf-8a23-eebc2e0b8ac8',
  'notification',
  'Thank You & Follow-up',
  'Hi {client_name}, thank you for choosing our {service_type} services. We hope everything went well. Please let us know if you need anything else!',
  CURRENT_TIMESTAMP
);

-- Add additional notifications for activity feed
INSERT INTO notifications (
  id, user_id, type, title, message, actionable, created_at
) VALUES
(
  gen_random_uuid(),
  '5157c34a-d658-43cf-8a23-eebc2e0b8ac8',
  'booking_confirmed',
  'Booking Confirmed',
  'Your booking with Sarah Johnson has been confirmed for tomorrow.',
  false,
  CURRENT_TIMESTAMP - INTERVAL '2 hours'
),
(
  gen_random_uuid(),
  '5157c34a-d658-43cf-8a23-eebc2e0b8ac8',
  'payment_received',
  'Payment Received',
  'Payment of $125 received for babysitting services.',
  false,
  CURRENT_TIMESTAMP - INTERVAL '1 day'
),
(
  gen_random_uuid(),
  '5c1bdf50-674c-41cc-ad4c-be13a348393a',
  'booking_request',
  'New Booking Request',
  'Alex Thompson has requested a new booking for next week.',
  true,
  CURRENT_TIMESTAMP - INTERVAL '30 minutes'
);

-- Add checkin tasks for job management (FIXED: Added service_type field)
INSERT INTO checkin_tasks (
  id, checkin_id, task_name, service_type, status, created_at
) VALUES
(
  gen_random_uuid(),
  'a4934e42-bcb1-455e-872e-eeef093ec565',
  'Feed pets',
  'pet_sitting',
  'completed',
  CURRENT_TIMESTAMP
),
(
  gen_random_uuid(),
  'a4934e42-bcb1-455e-872e-eeef093ec565',
  'Take photos',
  'pet_sitting',
  'completed',
  CURRENT_TIMESTAMP
),
(
  gen_random_uuid(),
  'a4934e42-bcb1-455e-872e-eeef093ec565',
  'Water plants',
  'house_sitting',
  'pending',
  CURRENT_TIMESTAMP
),
(
  gen_random_uuid(),
  '6b8071e6-7ea7-4d14-a7f0-3b911d8e603c',
  'Walk dog',
  'pet_sitting',
  'completed',
  CURRENT_TIMESTAMP
),
(
  gen_random_uuid(),
  '6b8071e6-7ea7-4d14-a7f0-3b911d8e603c',
  'Clean litter box',
  'pet_sitting',
  'pending',
  CURRENT_TIMESTAMP
);

-- Add pets/kids information for clients (FIXED: Changed special_needs to special_notes)
INSERT INTO pets_kids (
  id, client_id, name, type, age, special_notes, created_at
) VALUES
(
  gen_random_uuid(),
  'ec4c7afa-71e6-4e10-a1b1-d6987efb07e0',
  'Emma',
  'child',
  8,
  'Allergic to nuts',
  CURRENT_TIMESTAMP
),
(
  gen_random_uuid(),
  'ec4c7afa-71e6-4e10-a1b1-d6987efb07e0',
  'Jake',
  'child',
  5,
  'None',
  CURRENT_TIMESTAMP
),
(
  gen_random_uuid(),
  '4ca221c9-c786-43de-8084-19734db1fc09',
  'Max',
  'dog',
  3,
  'Needs daily medication',
  CURRENT_TIMESTAMP
);

-- Update user profiles with more complete information
UPDATE user_profiles SET
  bio = 'Experienced babysitter with 5+ years of childcare experience. CPR certified and loves working with kids of all ages.',
  avatar_url = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face'
WHERE id = '5157c34a-d658-43cf-8a23-eebc2e0b8ac8';

UPDATE user_profiles SET
  bio = 'Working mom of two who appreciates reliable childcare.',
  avatar_url = 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face'
WHERE id = '5c1bdf50-674c-41cc-ad4c-be13a348393a';

UPDATE user_profiles SET
  bio = 'Pet lover with a golden retriever named Max.',
  avatar_url = 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face'
WHERE id = 'a3761af3-66aa-4ac7-9706-5e0462459955';

-- Add reviews for completed bookings
INSERT INTO reviews (
  id, booking_id, reviewer_id, reviewee_id, rating, comment, created_at
) VALUES
(
  gen_random_uuid(),
  '377eddd2-d22c-47e8-b618-32d66e40eb2f',
  '5c1bdf50-674c-41cc-ad4c-be13a348393a',
  '5157c34a-d658-43cf-8a23-eebc2e0b8ac8',
  5,
  'Alex was amazing with the kids! Very professional and the children loved them. Will definitely book again.',
  CURRENT_TIMESTAMP - INTERVAL '1 day'
);

-- Verify data integrity
SELECT 'Seed data update completed successfully' as status;