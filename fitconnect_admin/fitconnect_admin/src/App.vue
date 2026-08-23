<template>
  <div class="min-h-screen bg-black text-white font-sans antialiased selection:bg-[#39FF14] selection:text-black">
    
    <!-- Top Navigation Bar -->
    <nav v-if="$route.name !== 'login'" class="border-b border-zinc-800/80 px-6 py-4 bg-black/90 backdrop-blur-md sticky top-0 z-50">
      <div class="max-w-7xl mx-auto flex justify-between items-center">
        
        <!-- Logo & Branding -->
        <router-link to="/" class="flex items-center gap-3 group">
          <img src="@/assets/fc.png" alt="FC" class="w-8 h-8 object-contain transition-transform group-hover:scale-105" />
          <h1 class="text-xl font-black tracking-widest text-white uppercase flex items-center gap-2">
            FITCONNECT <span class="text-[#39FF14] text-xs px-2 py-0.5 rounded bg-[#39FF14]/10 border border-[#39FF14]/30 font-black">ADMIN</span>
          </h1>
        </router-link>

        <!-- Navigation Links -->
        <div class="flex items-center gap-2 sm:gap-6">
          <router-link 
            to="/" 
            class="text-[11px] font-black uppercase tracking-wider px-3 py-2 rounded-xl text-zinc-400 hover:text-white transition"
            active-class="text-[#39FF14] bg-zinc-900 border border-zinc-800"
          >
            Overview
          </router-link>

          <router-link 
            to="/matches" 
            class="text-[11px] font-black uppercase tracking-wider px-3 py-2 rounded-xl text-zinc-400 hover:text-white transition"
            active-class="text-[#39FF14] bg-zinc-900 border border-zinc-800"
          >
            Matches
          </router-link>

          <router-link 
            to="/users" 
            class="text-[11px] font-black uppercase tracking-wider px-3 py-2 rounded-xl text-zinc-400 hover:text-white transition"
            active-class="text-[#39FF14] bg-zinc-900 border border-zinc-800"
          >
            Athletes
          </router-link>

          <router-link 
            to="/reports" 
            class="text-[11px] font-black uppercase tracking-wider px-3 py-2 rounded-xl text-zinc-400 hover:text-white transition flex items-center gap-1.5"
            active-class="text-red-400 bg-zinc-900 border border-zinc-800"
          >
            <span>Reports</span>
            <span v-if="pendingReportsCount > 0" class="px-1.5 py-0.2 text-[9px] rounded-full bg-red-500 text-white font-black">
              {{ pendingReportsCount }}
            </span>
          </router-link>
          
          <div class="h-4 w-px bg-zinc-800 mx-1 hidden sm:block"></div>

          <!-- Logout Button -->
          <button 
            @click="handleLogout" 
            class="text-[10px] font-black uppercase tracking-widest text-red-400 bg-red-500/10 border border-red-500/20 px-3.5 py-2 rounded-xl hover:bg-red-500 hover:text-white transition active:scale-95"
          >
            Logout
          </button>
        </div>
      </div>
    </nav>

    <!-- Main Content View -->
    <main :class="{ 'p-6 md:p-10': $route.name !== 'login' }">
      <router-view />
    </main>

  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from './lib/supabaseClient'
import { useRouter } from 'vue-router'

const router = useRouter()
const pendingReportsCount = ref(0)

const fetchPendingReports = async () => {
  try {
    const { count } = await supabase
      .from('reports')
      .select('*', { count: 'exact', head: true })
    pendingReportsCount.value = count || 0
  } catch {
    pendingReportsCount.value = 0
  }
}

const handleLogout = async () => {
  const { error } = await supabase.auth.signOut()
  if (!error) {
    router.push('/login')
  }
}

onMounted(() => {
  fetchPendingReports()
})
</script>