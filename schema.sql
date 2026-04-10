CREATE TABLE users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text,
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE calendar_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  date date NOT NULL,
  hebrew_date text,
  title_hebrew text NOT NULL,
  title_english text NOT NULL,
  description_hebrew text,
  description_english text,
  event_type text NOT NULL CHECK (event_type IN ('holiday', 'rosh_chodesh', 'fast_day', 'custom')),
  is_public boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE user_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  language_preference text DEFAULT 'bilingual' CHECK (language_preference IN ('hebrew', 'english', 'bilingual')),
  notification_enabled boolean DEFAULT false,
  notification_time time DEFAULT '09:00',
  start_week_on text DEFAULT 'sunday' CHECK (start_week_on IN ('sunday', 'monday', 'saturday')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE holiday_insights (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  holiday_key text UNIQUE NOT NULL,
  title_hebrew text NOT NULL,
  title_english text NOT NULL,
  long_description_hebrew text,
  long_description_english text,
  cultural_tips text[],
  traditional_foods text[],
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE holiday_insights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
ON users FOR SELECT
TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON users FOR UPDATE
TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Public can view public events"
ON calendar_events FOR SELECT
TO authenticated, anon
USING (is_public = true OR auth.uid() = user_id);

CREATE POLICY "Users can manage their own events"
ON calendar_events FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own settings"
ON user_settings FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings"
ON user_settings FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Everyone can view holiday insights"
ON holiday_insights FOR SELECT
TO authenticated, anon
USING (true);

CREATE POLICY "Only admins can modify holiday insights"
ON holiday_insights FOR ALL
TO authenticated
USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.email LIKE '%@admin.%'))
WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.email LIKE '%@admin.%'));

CREATE INDEX idx_calendar_events_user_id ON calendar_events(user_id);
CREATE INDEX idx_calendar_events_date ON calendar_events(date);
CREATE INDEX idx_calendar_events_event_type ON calendar_events(event_type);
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON calendar_events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_holiday_insights_updated_at BEFORE UPDATE ON holiday_insights FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();