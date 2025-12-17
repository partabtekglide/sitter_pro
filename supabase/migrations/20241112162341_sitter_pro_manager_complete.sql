-- Location: supabase/migrations/20241112162341_sitter_pro_manager_complete.sql
-- Sitter Pro Manager - Complete Backend Implementation
-- Schema Analysis: Fresh database setup
-- Integration Type: Complete new schema with authentication
-- Dependencies: None (fresh project setup)

-- 1. Custom Types
CREATE TYPE public.user_role AS ENUM ('sitter', 'client', 'admin');
CREATE TYPE public.service_type AS ENUM ('babysitting', 'pet_sitting', 'house_sitting', 'elder_care');
CREATE TYPE public.booking_status AS ENUM ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled');
CREATE TYPE public.communication_type AS ENUM ('message', 'call', 'notification');
CREATE TYPE public.notification_type AS ENUM ('booking_request', 'booking_confirmed', 'payment_received', 'reminder', 'message', 'review');

-- 2. Core Tables
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    avatar_url TEXT,
    role public.user_role DEFAULT 'client'::public.user_role,
    bio TEXT,
    hourly_rate DECIMAL(8,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    special_instructions TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.pets_kids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES public.clients(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'pet' or 'child'
    age INTEGER,
    special_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES public.clients(id) ON DELETE CASCADE,
    sitter_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    service_type public.service_type NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    start_time TIME NOT NULL,
    end_time TIME,
    hourly_rate DECIMAL(8,2) NOT NULL,
    total_amount DECIMAL(10,2),
    duration_hours INTEGER,
    special_instructions TEXT,
    address TEXT NOT NULL,
    status public.booking_status DEFAULT 'pending'::public.booking_status,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.communications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    type public.communication_type NOT NULL,
    subject TEXT,
    content TEXT,
    is_read BOOLEAN DEFAULT false,
    call_duration INTEGER, -- in minutes, for call type
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    type public.notification_type NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    actionable BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
    reviewer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    reviewee_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Essential Indexes
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX idx_user_profiles_is_active ON public.user_profiles(is_active);
CREATE INDEX idx_clients_user_id ON public.clients(user_id);
CREATE INDEX idx_pets_kids_client_id ON public.pets_kids(client_id);
CREATE INDEX idx_bookings_client_id ON public.bookings(client_id);
CREATE INDEX idx_bookings_sitter_id ON public.bookings(sitter_id);
CREATE INDEX idx_bookings_status ON public.bookings(status);
CREATE INDEX idx_bookings_start_date ON public.bookings(start_date);
CREATE INDEX idx_communications_sender_id ON public.communications(sender_id);
CREATE INDEX idx_communications_receiver_id ON public.communications(receiver_id);
CREATE INDEX idx_communications_booking_id ON public.communications(booking_id);
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX idx_reviews_booking_id ON public.reviews(booking_id);

-- 4. Functions for automatic profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, role, avatar_url, phone)
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)), 
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'client'::public.user_role),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone', '')
    );
    RETURN NEW;
END;
$$;

-- Create trigger for automatic profile creation
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pets_kids ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies - Following Correct Patterns

-- Pattern 1: Core user table (user_profiles)
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for clients
CREATE POLICY "users_manage_own_clients"
ON public.clients
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 7: Complex relationship for pets_kids (accessing via client relationship)
CREATE OR REPLACE FUNCTION public.can_access_pets_kids(pets_kids_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.pets_kids pk
    JOIN public.clients c ON pk.client_id = c.id
    WHERE pk.id = pets_kids_id AND c.user_id = auth.uid()
)
$$;

CREATE POLICY "users_manage_own_pets_kids"
ON public.pets_kids
FOR ALL
TO authenticated
USING (public.can_access_pets_kids(id))
WITH CHECK (public.can_access_pets_kids(id));

-- Pattern 7: Complex booking access (client or sitter can access)
CREATE OR REPLACE FUNCTION public.can_access_booking(booking_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.bookings b
    JOIN public.clients c ON b.client_id = c.id
    WHERE b.id = booking_id 
    AND (c.user_id = auth.uid() OR b.sitter_id = auth.uid())
)
$$;

CREATE POLICY "users_access_own_bookings"
ON public.bookings
FOR ALL
TO authenticated
USING (public.can_access_booking(id))
WITH CHECK (public.can_access_booking(id));

-- Pattern 7: Communication access (sender or receiver)
CREATE OR REPLACE FUNCTION public.can_access_communication(comm_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.communications
    WHERE id = comm_id 
    AND (sender_id = auth.uid() OR receiver_id = auth.uid())
)
$$;

CREATE POLICY "users_access_own_communications"
ON public.communications
FOR ALL
TO authenticated
USING (public.can_access_communication(id))
WITH CHECK (public.can_access_communication(id));

-- Pattern 2: Simple user ownership for notifications
CREATE POLICY "users_manage_own_notifications"
ON public.notifications
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 7: Review access (reviewer or reviewee)
CREATE OR REPLACE FUNCTION public.can_access_review(review_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.reviews
    WHERE id = review_id 
    AND (reviewer_id = auth.uid() OR reviewee_id = auth.uid())
)
$$;

CREATE POLICY "users_access_own_reviews"
ON public.reviews
FOR ALL
TO authenticated
USING (public.can_access_review(id))
WITH CHECK (public.can_access_review(id));

-- 7. Mock Data with Complete Auth Users
DO $$
DECLARE
    sitter_uuid UUID := gen_random_uuid();
    client1_uuid UUID := gen_random_uuid();
    client2_uuid UUID := gen_random_uuid();
    client1_id UUID := gen_random_uuid();
    client2_id UUID := gen_random_uuid();
    booking1_id UUID := gen_random_uuid();
    booking2_id UUID := gen_random_uuid();
    booking3_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users with required fields
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (sitter_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'sitter@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Alex Thompson", "role": "sitter", "phone": "+1 (555) 123-4567"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (client1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'sarah@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sarah Johnson", "role": "client", "phone": "+1 (555) 987-6543"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (client2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'mike@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Mike Chen", "role": "client", "phone": "+1 (555) 456-7890"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Update user profiles (created by trigger)
    UPDATE public.user_profiles SET 
        hourly_rate = 25.00,
        bio = 'Experienced babysitter with 5+ years of childcare experience. CPR certified.',
        address = '123 Main Street, Springfield, IL 62701'
    WHERE id = sitter_uuid;

    UPDATE public.user_profiles SET 
        address = '456 Oak Street, Springfield, IL 62702'
    WHERE id = client1_uuid;

    UPDATE public.user_profiles SET 
        address = '789 Pine Avenue, Springfield, IL 62703'
    WHERE id = client2_uuid;

    -- Create client records
    INSERT INTO public.clients (id, user_id, emergency_contact_name, emergency_contact_phone, special_instructions)
    VALUES 
        (client1_id, client1_uuid, 'John Johnson', '+1 (555) 111-2222', 'Kids love pizza for lunch'),
        (client2_id, client2_uuid, 'Lisa Chen', '+1 (555) 333-4444', 'Dog needs walk at 3 PM');

    -- Create pets/kids
    INSERT INTO public.pets_kids (client_id, name, type, age, special_notes)
    VALUES 
        (client1_id, 'Emma', 'child', 5, 'Loves to read before bedtime'),
        (client1_id, 'Jake', 'child', 3, 'Takes nap at 1 PM'),
        (client2_id, 'Max', 'pet', 4, 'Golden Retriever, very friendly');

    -- Create bookings
    INSERT INTO public.bookings (id, client_id, sitter_id, service_type, start_date, end_date, start_time, end_time, hourly_rate, total_amount, duration_hours, address, status)
    VALUES 
        (booking1_id, client1_id, sitter_uuid, 'babysitting'::public.service_type, CURRENT_DATE + INTERVAL '1 day', CURRENT_DATE + INTERVAL '1 day', '09:00', '14:00', 25.00, 125.00, 5, '456 Oak Street, Springfield, IL 62702', 'confirmed'::public.booking_status),
        (booking2_id, client2_id, sitter_uuid, 'pet_sitting'::public.service_type, CURRENT_DATE, CURRENT_DATE, '16:00', '18:00', 20.00, 40.00, 2, '789 Pine Avenue, Springfield, IL 62703', 'pending'::public.booking_status),
        (booking3_id, client1_id, sitter_uuid, 'babysitting'::public.service_type, CURRENT_DATE + INTERVAL '3 days', CURRENT_DATE + INTERVAL '3 days', '18:30', '23:00', 25.00, 112.50, 4, '456 Oak Street, Springfield, IL 62702', 'confirmed'::public.booking_status);

    -- Create communications
    INSERT INTO public.communications (sender_id, receiver_id, booking_id, type, subject, content, is_read)
    VALUES 
        (client1_uuid, sitter_uuid, booking1_id, 'message'::public.communication_type, 'Tomorrow''s Appointment', 'Can you arrive 15 minutes early today?', false),
        (sitter_uuid, client2_uuid, booking2_id, 'message'::public.communication_type, 'Pet Care', 'Thanks for trusting me with Max today!', true),
        (client1_uuid, sitter_uuid, null, 'call'::public.communication_type, 'Quick Check-in', '', true);

    -- Create notifications
    INSERT INTO public.notifications (user_id, booking_id, type, title, message, is_read, actionable)
    VALUES 
        (sitter_uuid, booking1_id, 'booking_request'::public.notification_type, 'New booking request', 'Sarah Johnson requested babysitting for tomorrow', false, true),
        (sitter_uuid, null, 'payment_received'::public.notification_type, 'Payment received', '$75.00 from Mike Chen for pet sitting', false, false),
        (sitter_uuid, booking3_id, 'reminder'::public.notification_type, 'Appointment reminder', 'House sitting with Emily Rodriguez in 1 hour', true, true);

    -- Create a review
    INSERT INTO public.reviews (booking_id, reviewer_id, reviewee_id, rating, comment)
    VALUES 
        (booking1_id, client1_uuid, sitter_uuid, 5, 'Alex was amazing with the kids! Very professional and caring.');

END $$;