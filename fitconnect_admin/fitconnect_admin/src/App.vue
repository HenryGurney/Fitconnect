<template>
  <div class="min-h-screen bg-black text-white font-sans">
    
    <nav v-if="$route.name !== 'login'" class="border-b border-zinc-800 p-4 bg-black sticky top-0 z-50">
      <div class="max-w-7xl mx-auto flex justify-between items-center">
        
        <div class="flex items-center gap-3">
          <img src="@/assets/fc.png" alt="FC" class="w-8 h-8 object-contain" />
          <h1 class="text-xl font-black tracking-widest text-white uppercase">
            FITCONNECT <span class="text-neon-green text-sm italic">ADMIN</span>
          </h1>
        </div>

        <div class="flex gap-8 items-center">
          <router-link 
            to="/" 
            class="text-[10px] font-black uppercase tracking-widest hover:text-neon-green transition"
            active-class="text-neon-green"
          >
            Stats
          </router-link>
          <router-link 
            to="/users" 
            class="text-[10px] font-black uppercase tracking-widest hover:text-neon-green transition"
            active-class="text-neon-green"
          >
            Users
          </router-link>
          
          <button 
            @click="handleLogout" 
            class="text-[10px] font-black uppercase tracking-widest text-red-500 border border-red-500/30 px-4 py-2 rounded-lg hover:bg-red-500 hover:text-white transition-all"
          >
            Logout
          </button>
        </div>
      </div>
    </nav>

    <main :class="{ 'p-8': $route.name !== 'login' }">
      <router-view />
    </main>

  </div>
</template>

<script setup>
import { supabase } from './lib/supabaseClient'
import { useRouter } from 'vue-router'

const router = useRouter()

const handleLogout = async () => {
  const { error } = await supabase.auth.signOut()
  if (!error) {
    router.push('/login')
  }
}
</script>