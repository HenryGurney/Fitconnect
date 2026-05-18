import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://tezarjmgnvsgfkfjwqmu.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlemFyam1nbnZzZ2ZrZmp3cW11Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNDIyNDMsImV4cCI6MjA5MzkxODI0M30.Zy5UrueA2kxw2450LtqqMHCicGzL91rbr0KnVXke7sk' // Use your key from Supabase dashboard

export const supabase = createClient(supabaseUrl, supabaseAnonKey)