<template>
  <div class="max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-8">
      <div>
        <h2 class="text-3xl font-black text-white uppercase italic tracking-tighter">
          Platform <span class="text-[#39FF14]">Overview</span>
        </h2>
        <p class="text-zinc-500 text-xs font-bold uppercase tracking-widest mt-1">
          FitConnect Real-Time System Intelligence
        </p>
      </div>

      <div class="flex items-center gap-3">
        <button 
          @click="fetchAllMetrics"
          class="flex items-center gap-2 px-4 py-2 bg-zinc-900 border border-zinc-800 rounded-xl hover:border-zinc-700 text-xs font-bold text-zinc-300 hover:text-white transition active:scale-95"
        >
          <svg class="w-3.5 h-3.5 text-[#39FF14]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Sync Live Data
        </button>
      </div>
    </div>

    <!-- 4 High-Impact Real Metrics -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-10">
      
      <!-- 1. Matches -->
      <div class="bg-zinc-900 border border-zinc-800 p-6 rounded-3xl group hover:border-zinc-700 transition-all">
        <div class="flex justify-between items-start">
          <p class="text-zinc-500 text-[10px] font-black uppercase tracking-widest">Active Match Lobbies</p>
          <span class="text-lg">⚽</span>
        </div>
        <p class="text-4xl font-black text-white mt-3 tabular-nums">
          {{ loading ? '...' : matchCount }}
        </p>
        <div class="flex items-center gap-2 mt-3">
          <span class="text-[#39FF14] text-xs font-bold">Live</span>
          <span class="text-zinc-500 text-xs">Community matches</span>
        </div>
      </div>

      <!-- 2. Registered Athletes -->
      <div class="bg-zinc-900 border border-zinc-800 p-6 rounded-3xl border-l-4 border-l-[#39FF14] relative overflow-hidden">
        <div class="flex justify-between items-start">
          <p class="text-zinc-500 text-[10px] font-black uppercase tracking-widest">Athletes</p>
          <span class="text-lg">🏃</span>
        </div>
        <p class="text-4xl font-black text-white mt-3 tabular-nums">
          {{ loading ? '...' : athleteCount }}
        </p>
        <div class="text-zinc-500 text-xs mt-3">Verified user accounts</div>
        <div class="absolute -right-4 -bottom-4 w-20 h-20 bg-[#39FF14]/5 blur-2xl rounded-full"></div>
      </div>

      <!-- 3. PRO Members -->
      <div class="bg-zinc-900 border border-zinc-800 p-6 rounded-3xl group hover:border-amber-400/30 transition-all">
        <div class="flex justify-between items-start">
          <p class="text-zinc-500 text-[10px] font-black uppercase tracking-widest">PRO Subscribers</p>
          <span class="text-lg">👑</span>
        </div>
        <p class="text-4xl font-black text-amber-400 mt-3 tabular-nums">
          {{ loading ? '...' : proCount }}
        </p>
        <div class="text-zinc-500 text-xs mt-3">FitConnect PRO Tier</div>
      </div>

      <!-- 4. Community Reports -->
      <div class="bg-zinc-900 border border-zinc-800 p-6 rounded-3xl group hover:border-red-500/30 transition-all">
        <div class="flex justify-between items-start">
          <p class="text-zinc-500 text-[10px] font-black uppercase tracking-widest">Incident Reports</p>
          <span class="text-lg">🚩</span>
        </div>
        <p class="text-4xl font-black mt-3 tabular-nums" :class="reportCount > 0 ? 'text-red-400' : 'text-zinc-400'">
          {{ loading ? '...' : reportCount }}
        </p>
        <div class="text-zinc-500 text-xs mt-3">Logged dispute cases</div>
      </div>

    </div>

    <!-- Sport Breakdown & Live Activity Feeds -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-10">
      
      <!-- Sport Distribution (Computed from real matches) -->
      <div class="bg-zinc-900/60 border border-zinc-800 rounded-3xl p-6">
        <div class="flex justify-between items-center mb-6">
          <h3 class="text-sm font-black text-white uppercase tracking-wider">Sport Popularity</h3>
          <span class="text-[10px] font-mono text-zinc-500">BY LOBBY VOLUME</span>
        </div>

        <div v-if="loading" class="text-center py-10 text-zinc-500 text-xs animate-pulse">
          Calculating sport analytics...
        </div>

        <div v-else-if="sportStats.length === 0" class="text-center py-10 text-zinc-500 text-xs">
          No matches hosted yet to generate sports metrics.
        </div>

        <div v-else class="space-y-4">
          <div v-for="item in sportStats" :key="item.sport">
            <div class="flex justify-between text-xs font-bold mb-1.5">
              <span class="text-zinc-300">{{ item.sport }}</span>
              <span class="text-[#39FF14] tabular-nums">{{ item.count }} ({{ item.percentage }}%)</span>
            </div>
            <div class="w-full bg-zinc-800 h-2 rounded-full overflow-hidden">
              <div 
                class="bg-[#39FF14] h-full rounded-full transition-all duration-500"
                :style="{ width: `${item.percentage}%` }"
              ></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Live Recent Matches -->
      <div class="bg-zinc-900/60 border border-zinc-800 rounded-3xl p-6">
        <div class="flex justify-between items-center mb-6">
          <h3 class="text-sm font-black text-white uppercase tracking-wider">Recent Matches Hosted</h3>
          <router-link to="/matches" class="text-[10px] text-[#39FF14] hover:underline font-bold uppercase">
            View All →
          </router-link>
        </div>

        <div v-if="loading" class="text-center py-10 text-zinc-500 text-xs animate-pulse">
          Loading recent matches...
        </div>

        <div v-else-if="recentMatches.length === 0" class="text-center py-10 text-zinc-500 text-xs">
          No match lobbies created yet.
        </div>

        <div v-else class="space-y-3">
          <div 
            v-for="m in recentMatches" 
            :key="m.id"
            class="flex items-center justify-between p-3 bg-zinc-950/70 border border-zinc-800/50 rounded-xl"
          >
            <div>
              <div class="text-xs font-bold text-white">{{ m.title || 'Casual Game' }}</div>
              <div class="text-[10px] text-zinc-500">📍 {{ m.location_name || 'Venue' }} • {{ m.sport }}</div>
            </div>
            <span class="px-2 py-0.5 rounded bg-zinc-800 text-[#39FF14] text-[10px] font-bold">
              {{ m.fee_per_pax || 'Free' }}
            </span>
          </div>
        </div>
      </div>

      <!-- Live Newly Registered Athletes -->
      <div class="bg-zinc-900/60 border border-zinc-800 rounded-3xl p-6">
        <div class="flex justify-between items-center mb-6">
          <h3 class="text-sm font-black text-white uppercase tracking-wider">Newest Athletes</h3>
          <router-link to="/users" class="text-[10px] text-[#39FF14] hover:underline font-bold uppercase">
            Manage All →
          </router-link>
        </div>

        <div v-if="loading" class="text-center py-10 text-zinc-500 text-xs animate-pulse">
          Loading athletes...
        </div>

        <div v-else-if="recentAthletes.length === 0" class="text-center py-10 text-zinc-500 text-xs">
          No athletes registered yet.
        </div>

        <div v-else class="space-y-3">
          <div 
            v-for="a in recentAthletes" 
            :key="a.id"
            class="flex items-center justify-between p-3 bg-zinc-950/70 border border-zinc-800/50 rounded-xl"
          >
            <div class="flex items-center gap-2.5">
              <div class="w-7 h-7 rounded-full bg-zinc-800 flex items-center justify-center text-[#39FF14] text-xs font-bold">
                {{ a.name ? a.name[0].toUpperCase() : '?' }}
              </div>
              <div>
                <div class="text-xs font-bold text-white">{{ a.name || 'Anonymous' }}</div>
                <div class="text-[10px] text-zinc-500">{{ a.sport || 'Athlete' }} • {{ a.location || 'Local' }}</div>
              </div>
            </div>
            <span 
              class="text-[10px] font-mono font-bold"
              :class="(a.reliability_score ?? 100) >= 90 ? 'text-[#39FF14]' : 'text-amber-400'"
            >
              {{ a.reliability_score ?? 100 }}%
            </span>
          </div>
        </div>
      </div>

    </div>

    <!-- Quick Action Moderation Banner -->
    <div class="bg-gradient-to-r from-zinc-900 via-zinc-900 to-black border border-zinc-800 p-8 rounded-[2rem] flex flex-col md:flex-row justify-between items-center gap-6">
      <div>
        <h3 class="text-xl font-black text-white uppercase tracking-tight">Need to review incident reports?</h3>
        <p class="text-zinc-400 text-xs mt-1">
          Keep community reliability high by moderating no-shows and player disputes.
        </p>
      </div>
      <div class="flex items-center gap-3">
        <router-link 
          to="/reports" 
          class="bg-red-500/10 text-red-400 border border-red-500/20 font-black px-6 py-3 rounded-xl hover:bg-red-500 hover:text-white transition uppercase text-xs"
        >
          Review Reports ({{ reportCount }})
        </router-link>
        <router-link 
          to="/matches" 
          class="bg-white text-black font-black px-6 py-3 rounded-xl hover:bg-[#39FF14] hover:text-black transition uppercase text-xs"
        >
          Manage Lobbies
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabaseClient'

const loading = ref(true)
const athleteCount = ref(0)
const matchCount = ref(0)
const proCount = ref(0)
const reportCount = ref(0)

const sportStats = ref([])
const recentMatches = ref([])
const recentAthletes = ref([])

const fetchAllMetrics = async () => {
  loading.value = true
  try {
    // 1. Total athletes & pro counts
    const { data: athletes } = await supabase
      .from('profiles')
      .select('*')

    if (athletes) {
      const nonAdmins = athletes.filter(a => a.is_admin !== true)
      athleteCount.value = nonAdmins.length
      proCount.value = nonAdmins.filter(a => a.tier === 'pro' || a.is_premium).length
      recentAthletes.value = nonAdmins.slice(0, 5)
    }

    // 2. Matches & sport breakdown
    const { data: matches } = await supabase
      .from('lobbies')
      .select('*')

    if (matches) {
      matchCount.value = matches.length
      recentMatches.value = matches.slice(0, 5)

      // Calculate real sport popularity
      const counts = {}
      matches.forEach(m => {
        const s = m.sport || 'Other'
        counts[s] = (counts[s] || 0) + 1
      })

      const total = matches.length || 1
      sportStats.value = Object.keys(counts)
        .map(sport => ({
          sport,
          count: counts[sport],
          percentage: Math.round((counts[sport] / total) * 100)
        }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 5)
    }

    // 3. Incident reports count
    try {
      const { count: totalReports } = await supabase
        .from('reports')
        .select('*', { count: 'exact', head: true })
      reportCount.value = totalReports || 0
    } catch {
      reportCount.value = 0
    }

  } catch (err) {
    console.error('Error fetching metrics:', err.message)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchAllMetrics()
})
</script>