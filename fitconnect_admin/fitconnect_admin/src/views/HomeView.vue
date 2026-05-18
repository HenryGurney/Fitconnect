<template>
  <div class="max-w-7xl mx-auto">
    <div class="mb-10">
      <h2 class="text-3xl font-black text-white uppercase italic tracking-tighter">
        Platform <span class="text-neon-green">Overview</span>
      </h2>
      <p class="text-zinc-500 text-[10px] font-black uppercase tracking-[0.3em] mt-1">
        FitConnect System Intelligence
      </p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
      
      <div class="bg-zinc-900 border border-zinc-800 p-8 rounded-3xl group hover:border-zinc-700 transition-all">
        <p class="text-zinc-500 text-[10px] font-black uppercase tracking-widest">Total Sports Matches</p>
        <p class="text-5xl font-black text-white mt-3 tabular-nums">128</p>
        <div class="flex items-center gap-2 mt-4">
          <span class="text-neon-green text-xs font-bold">+12%</span>
          <span class="text-zinc-600 text-xs font-medium italic">Increased activity</span>
        </div>
      </div>

      <div class="bg-zinc-900 border border-zinc-800 p-8 rounded-3xl border-l-4 border-l-neon-green relative overflow-hidden">
        <div class="relative z-10">
          <p class="text-zinc-500 text-[10px] font-black uppercase tracking-widest">Registered Athletes</p>
          <p class="text-5xl font-black text-white mt-3 tabular-nums">
            {{ loading ? '...' : athleteCount }}
          </p>
          <div class="text-zinc-500 text-xs font-bold mt-4">Verified Database Profiles</div>
        </div>
        <div class="absolute -right-4 -bottom-4 w-24 h-24 bg-neon-green/5 blur-3xl rounded-full"></div>
      </div>

      <div class="bg-zinc-900 border border-zinc-800 p-8 rounded-3xl flex flex-col justify-between">
        <div>
          <p class="text-zinc-500 text-[10px] font-black uppercase tracking-widest">Global System Status</p>
          <p class="text-5xl font-black text-neon-green mt-3 drop-shadow-[0_0_15px_rgba(57,255,20,0.5)] animate-pulse">
            LIVE
          </p>
        </div>
        <div class="flex items-center gap-2 mt-4 bg-zinc-950 px-3 py-1.5 rounded-full w-fit border border-zinc-800">
          <div class="w-2 h-2 rounded-full bg-neon-green animate-ping"></div>
          <span class="text-zinc-400 text-[9px] font-black uppercase">Server: Singapore-01</span>
        </div>
      </div>

    </div>

    <div class="bg-gradient-to-r from-zinc-900 to-black border border-zinc-800 p-10 rounded-[2.5rem] flex flex-col md:flex-row justify-between items-center gap-6">
      <div class="text-center md:text-left">
        <h3 class="text-2xl font-black text-white uppercase tracking-tighter">Ready to moderate?</h3>
        <p class="text-zinc-500 font-medium max-w-md mt-2">
          New athletes have joined the platform. Review their skill levels and sports preferences to ensure community quality.
        </p>
      </div>
      <router-link 
        to="/users" 
        class="bg-white text-black font-black px-8 py-4 rounded-2xl hover:bg-neon-green hover:shadow-[0_0_30px_rgba(57,255,20,0.3)] transition-all active:scale-95 uppercase text-sm"
      >
        Go to User Management
      </router-link>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabaseClient'

const athleteCount = ref(0)
const loading = ref(true)

const fetchAthleteCount = async () => {
  loading.value = true
  try {
    // We use { count: 'exact', head: true } to get the number of rows 
    // without actually downloading all the user data (Save bandwidth!)
    const { count, error } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true })
      .eq('is_admin', false)

    if (error) throw error
    athleteCount.value = count || 0
  } catch (err) {
    console.error('Error fetching count:', err.message)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchAthleteCount()
})
</script>

<style scoped>
/* Optional: Adding a custom font feel if you have one, or just extra spacing */
.tabular-nums {
  font-variant-numeric: tabular-nums;
}
</style>