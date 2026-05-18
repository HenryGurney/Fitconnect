<template>
  <div class="min-h-screen flex items-center justify-center bg-black p-6 font-sans">
    <div class="w-full max-w-md bg-zinc-900 border border-zinc-800 p-10 rounded-3xl shadow-2xl">
      
    <div class="text-center mb-10">
        <div class="inline-block mb-4">
            <img 
            src="@/assets/fc.png" 
            alt="FitConnect Logo" 
            class="w-24 h-24 object-contain mx-auto" 
            />
        </div>
        
        <h1 class="text-3xl font-black tracking-tighter text-white uppercase">
            FitConnect <span class="text-neon-green italic">Admin</span>
        </h1>
        <p class="text-zinc-500 text-[10px] font-black uppercase tracking-[0.3em] mt-2">
            Authorized Personnel Only
        </p>
    </div>

      <form @submit.prevent="handleLogin" class="space-y-5">
        <div>
          <label class="block text-[10px] font-black text-zinc-500 uppercase mb-2 ml-1">Terminal ID (Email)</label>
          <input 
            v-model="email" 
            type="email" 
            required 
            placeholder="admin@fitconnect.com"
            class="w-full bg-black border border-zinc-800 rounded-xl p-4 text-white focus:border-neonGreen focus:ring-1 focus:ring-neonGreen outline-none transition-all placeholder:text-zinc-700" 
          />
        </div>
        
        <div>
          <label class="block text-[10px] font-black text-zinc-500 uppercase mb-2 ml-1">Access Key (Password)</label>
          <input 
            v-model="password" 
            type="password" 
            required 
            placeholder="••••••••"
            class="w-full bg-black border border-zinc-800 rounded-xl p-4 text-white focus:border-neonGreen focus:ring-1 focus:ring-neonGreen outline-none transition-all placeholder:text-zinc-700" 
          />
        </div>

        <button 
          :disabled="loading" 
          type="submit" 
          class="w-full bg-neonGreen text-black font-black py-4 rounded-xl hover:scale-[1.02] active:scale-[0.98] transition-all shadow-[0_0_30px_rgba(57,255,20,0.2)] disabled:opacity-50 mt-4"
        >
          {{ loading ? 'AUTHENTICATING...' : 'LOGIN' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { supabase } from '../lib/supabaseClient'
import { useRouter } from 'vue-router'

const email = ref('')
const password = ref('')
const loading = ref(false)
const router = useRouter()

const handleLogin = async () => {
  loading.value = true
  
  // 1. Sign in via Supabase Auth
  const { data, error } = await supabase.auth.signInWithPassword({
    email: email.value,
    password: password.value
  })

  if (error) {
    alert("Authentication Failed: " + error.message)
    loading.value = false
    return
  }

  // 2. Role Verification: Check the is_admin column you just created
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('is_admin')
    .eq('id', data.user.id)
    .single()

  if (profile?.is_admin === true) {
    // Success - Go to the main dashboard
    router.push('/')
  } else {
    // Failed - Not an admin
    await supabase.auth.signOut()
    alert("CRITICAL ERROR: Unauthorized account detected. Admin privileges required.")
  }
  
  loading.value = false
}
</script>

<style scoped>
.text-neonGreen { color: #39FF14; }
.bg-neonGreen { background-color: #39FF14; }
</style>