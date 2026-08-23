<template>
  <div class="max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-8">
      <div>
        <h2 class="text-3xl font-black text-white uppercase italic tracking-tighter">
          Athlete <span class="text-[#39FF14]">Management</span>
        </h2>
        <p class="text-zinc-500 text-xs font-bold uppercase tracking-widest mt-1">
          Review, moderate, and adjust FitConnect athlete profiles
        </p>
      </div>

      <div class="flex items-center gap-4">
        <div class="text-right">
          <span class="text-zinc-500 text-[10px] font-black uppercase">Registered Athletes</span>
          <p class="text-2xl font-black text-white tabular-nums">{{ filteredUsers.length }}</p>
        </div>
        <button 
          @click="fetchUsers"
          class="p-3 bg-zinc-900 border border-zinc-800 rounded-xl hover:border-zinc-700 text-zinc-400 hover:text-white transition active:scale-95"
          title="Refresh Athletes"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Filters & Search Bar -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
      <div class="relative">
        <input 
          v-model="searchQuery" 
          type="text" 
          placeholder="Search by name, email, sport, or location..."
          class="w-full bg-zinc-900/80 border border-zinc-800 rounded-xl px-4 py-3 pl-10 text-sm text-white focus:border-[#39FF14] focus:ring-1 focus:ring-[#39FF14] outline-none transition placeholder:text-zinc-600"
        />
        <svg class="w-4 h-4 text-zinc-500 absolute left-3.5 top-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </div>

      <div>
        <select 
          v-model="selectedTier"
          class="w-full bg-zinc-900/80 border border-zinc-800 rounded-xl px-4 py-3 text-sm text-white focus:border-[#39FF14] outline-none transition"
        >
          <option value="">All Tiers (Free & Pro)</option>
          <option value="pro">👑 PRO Athletes Only</option>
          <option value="free">Free Tier Only</option>
        </select>
      </div>

      <div>
        <select 
          v-model="selectedReliability"
          class="w-full bg-zinc-900/80 border border-zinc-800 rounded-xl px-4 py-3 text-sm text-white focus:border-[#39FF14] outline-none transition"
        >
          <option value="">All Reliability Scores</option>
          <option value="elite">🛡️ High / Elite (>= 90%)</option>
          <option value="warning">⚠️ Low / At Risk (&lt; 75%)</option>
        </select>
      </div>

      <div>
        <select 
          v-model="selectedStatus"
          class="w-full bg-zinc-900/80 border border-zinc-800 rounded-xl px-4 py-3 text-sm text-white focus:border-[#39FF14] outline-none transition"
        >
          <option value="">All Account Statuses</option>
          <option value="active">Active Athletes</option>
          <option value="banned">Suspended / Banned</option>
        </select>
      </div>
    </div>

    <!-- Table Container -->
    <div class="bg-zinc-900/50 rounded-2xl border border-zinc-800 overflow-hidden shadow-2xl">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead class="bg-zinc-800/50 text-[#39FF14] text-[10px] font-black uppercase tracking-[0.2em]">
            <tr>
              <th class="p-5">Athlete Info</th>
              <th class="p-5">Primary Sport & Skill</th>
              <th class="p-5">Location</th>
              <th class="p-5">Tier</th>
              <th class="p-5 text-center">Reliability Score</th>
              <th class="p-5 text-center">Status</th>
              <th class="p-5 text-right">Moderation</th>
            </tr>
          </thead>
          
          <tbody class="text-sm">
            <tr v-if="loading">
              <td colspan="7" class="p-20 text-center text-zinc-500 font-bold animate-pulse">
                INITIALIZING ATHLETE DATABASE...
              </td>
            </tr>

            <tr v-else-if="filteredUsers.length === 0">
              <td colspan="7" class="p-20 text-center text-zinc-500 font-bold">
                NO ATHLETES MATCH THE FILTER CRITERIA.
              </td>
            </tr>

            <tr 
              v-for="user in filteredUsers" 
              :key="user.id" 
              class="border-t border-zinc-800/50 hover:bg-[#39FF14]/5 transition-colors group"
            >
              <!-- 1. Athlete Info -->
              <td class="p-5">
                <div class="flex items-center gap-3">
                  <img 
                    v-if="user.image_url" 
                    :src="user.image_url" 
                    alt="Avatar" 
                    class="w-10 h-10 rounded-full object-cover border border-zinc-700" 
                  />
                  <div 
                    v-else 
                    class="w-10 h-10 rounded-full bg-zinc-800 border border-zinc-700 flex items-center justify-center text-[#39FF14] font-black"
                  >
                    {{ user.name ? user.name[0].toUpperCase() : '?' }}
                  </div>
                  <div>
                    <div class="font-bold text-white group-hover:text-[#39FF14] transition-colors flex items-center gap-2">
                      {{ user.name || 'Anonymous Athlete' }}
                      <span v-if="user.tier === 'pro' || user.is_premium" class="text-amber-400 text-xs" title="PRO Member">👑</span>
                    </div>
                    <div class="text-[10px] text-zinc-500 font-mono">{{ user.email || user.id.slice(0, 12) + '...' }}</div>
                  </div>
                </div>
              </td>

              <!-- 2. Sport & Skill -->
              <td class="p-5">
                <div class="flex flex-col gap-1">
                  <span class="px-2 py-0.5 rounded bg-zinc-800 text-zinc-300 text-[10px] font-bold uppercase tracking-wider w-fit">
                    {{ user.sport || 'Multi-Sport' }}
                  </span>
                  <span class="text-xs text-zinc-400">{{ user.skill || user.skill_level || 'Beginner' }}</span>
                </div>
              </td>

              <!-- 3. Location -->
              <td class="p-5 text-xs text-zinc-400">
                📍 {{ user.location || 'Not Specified' }}
              </td>

              <!-- 4. Tier -->
              <td class="p-5">
                <span 
                  class="px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider inline-flex items-center gap-1"
                  :class="user.tier === 'pro' || user.is_premium 
                    ? 'bg-amber-400/10 text-amber-400 border border-amber-400/30' 
                    : 'bg-zinc-800 text-zinc-400'"
                >
                  <span v-if="user.tier === 'pro' || user.is_premium">⭐ PRO</span>
                  <span v-else>FREE</span>
                </span>
              </td>

              <!-- 5. Reliability Score -->
              <td class="p-5 text-center">
                <div class="inline-flex flex-col items-center gap-1">
                  <div class="flex items-center gap-1 font-mono font-bold text-xs">
                    <span :class="(user.reliability_score ?? 100) < 75 ? 'text-red-400' : 'text-[#39FF14]'">
                      {{ user.reliability_score ?? 100 }}%
                    </span>
                  </div>
                  <!-- Quick Score Buttons -->
                  <div class="flex items-center gap-1 mt-1">
                    <button 
                      @click="adjustScore(user, 5)"
                      class="px-1.5 py-0.5 bg-zinc-800 hover:bg-[#39FF14]/20 hover:text-[#39FF14] text-[9px] font-bold rounded text-zinc-400 transition"
                      title="Add +5% Score"
                    >
                      +5
                    </button>
                    <button 
                      @click="adjustScore(user, -5)"
                      class="px-1.5 py-0.5 bg-zinc-800 hover:bg-red-500/20 hover:text-red-400 text-[9px] font-bold rounded text-zinc-400 transition"
                      title="Deduct -5% Score"
                    >
                      -5
                    </button>
                  </div>
                </div>
              </td>

              <!-- 6. Status -->
              <td class="p-5 text-center">
                <div 
                  class="w-2.5 h-2.5 rounded-full mx-auto transition-all duration-300"
                  :class="user.is_banned 
                    ? 'bg-red-500 shadow-[0_0_8px_#EF4444]' 
                    : 'bg-[#39FF14] shadow-[0_0_12px_#39FF14]'"
                  :title="user.is_banned ? 'Suspended Account' : 'Active Account'"
                ></div>
              </td>

              <!-- 7. Actions -->
              <td class="p-5 text-right">
                <div class="flex items-center justify-end gap-2">
                  <button 
                    @click="toggleUserBan(user)"
                    class="px-3 py-1.5 rounded-xl text-[10px] font-black uppercase transition-all active:scale-95 border"
                    :class="user.is_banned
                      ? 'bg-[#39FF14]/10 text-[#39FF14] border-[#39FF14]/20 hover:bg-[#39FF14] hover:text-black shadow-[0_0_10px_rgba(57,255,20,0.1)]'
                      : 'bg-amber-500/10 text-amber-400 border-amber-500/20 hover:bg-amber-500 hover:text-black'"
                  >
                    {{ user.is_banned ? 'Unban' : 'Suspend' }}
                  </button>
                  <button 
                    @click="deleteUser(user)"
                    class="px-3 py-1.5 rounded-xl text-[10px] font-black uppercase bg-red-500/10 text-red-500 border border-red-500/20 hover:bg-red-500 hover:text-white transition active:scale-95"
                    title="Permanently Delete Athlete"
                  >
                    Delete
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabaseClient'

const users = ref([])
const loading = ref(true)

const searchQuery = ref('')
const selectedTier = ref('')
const selectedReliability = ref('')
const selectedStatus = ref('')

const fetchUsers = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')

    if (error) throw error
    // Filter non-admin users in JS safely and fallback gracefully
    users.value = (data || []).filter(u => u.is_admin !== true)
  } catch (error) {
    console.error('Error fetching users:', error.message)
  } finally {
    loading.value = false
  }
}

const filteredUsers = computed(() => {
  return users.value.filter(u => {
    // Search
    const q = searchQuery.value.toLowerCase()
    const name = (u.name || '').toLowerCase()
    const email = (u.email || '').toLowerCase()
    const sport = (u.sport || '').toLowerCase()
    const location = (u.location || '').toLowerCase()

    const matchesSearch = !q || name.includes(q) || email.includes(q) || sport.includes(q) || location.includes(q)

    // Tier
    let matchesTier = true
    if (selectedTier.value === 'pro') {
      matchesTier = u.tier === 'pro' || u.is_premium === true
    } else if (selectedTier.value === 'free') {
      matchesTier = u.tier !== 'pro' && !u.is_premium
    }

    // Reliability
    let matchesReliability = true
    const score = u.reliability_score ?? 100
    if (selectedReliability.value === 'elite') {
      matchesReliability = score >= 90
    } else if (selectedReliability.value === 'warning') {
      matchesReliability = score < 75
    }

    // Status
    let matchesStatus = true
    if (selectedStatus.value === 'active') {
      matchesStatus = !u.is_banned
    } else if (selectedStatus.value === 'banned') {
      matchesStatus = u.is_banned === true
    }

    return matchesSearch && matchesTier && matchesReliability && matchesStatus
  })
})

const adjustScore = async (user, delta) => {
  const current = user.reliability_score ?? 100
  const target = Math.max(0, Math.min(100, current + delta))

  try {
    const { error } = await supabase
      .from('profiles')
      .update({ reliability_score: target })
      .eq('id', user.id)

    if (error) throw error
    user.reliability_score = target
  } catch (e) {
    console.error('Error updating score:', e.message)
    alert('Failed to adjust score: ' + e.message)
  }
}

const toggleUserBan = async (user) => {
  const currentBanStatus = user.is_banned || false
  const actionText = currentBanStatus ? "UNBAN and restore" : "SUSPEND"
  
  const confirmed = confirm(`Are you sure you want to ${actionText} ${user.name || 'this athlete'}?`)
  if (!confirmed) return

  try {
    const targetScore = currentBanStatus ? 100 : (user.reliability_score ?? 100)

    const { error } = await supabase
      .from('profiles')
      .update({ 
        is_banned: !currentBanStatus,
        reliability_score: targetScore
      })
      .eq('id', user.id)

    if (error) throw error

    user.is_banned = !currentBanStatus
    user.reliability_score = targetScore
  } catch (error) {
    console.error('Moderation mutation rejected:', error.message)
    alert('Administrative action failed: ' + error.message)
  }
}

const deleteUser = async (user) => {
  const confirmed = confirm(
    `⚠️ PERMANENT DELETE:\nAre you sure you want to completely remove "${user.name || 'this athlete'}"?\n\nThis will purge their profile and associated match data. This action cannot be undone.`
  )
  if (!confirmed) return

  try {
    // 1. Clean up user references in related tables gracefully
    try { await supabase.from('lobby_participants').delete().eq('user_id', user.id) } catch (_) {}
    try { await supabase.from('lobbies').delete().eq('host_id', user.id) } catch (_) {}
    try { await supabase.from('reports').delete().eq('reported_user_id', user.id) } catch (_) {}
    try { await supabase.from('reports').delete().eq('reporter_id', user.id) } catch (_) {}
    try { await supabase.from('swipes').delete().eq('user_id', user.id) } catch (_) {}
    try { await supabase.from('swipes').delete().eq('target_user_id', user.id) } catch (_) {}

    // 2. Delete the profile record from database
    const { error } = await supabase.from('profiles').delete().eq('id', user.id)
    if (error) throw error

    // 3. Remove from UI list
    users.value = users.value.filter(u => u.id !== user.id)
    alert(`Athlete "${user.name || 'User'}" has been permanently deleted.`)
  } catch (error) {
    console.error('Failed to delete user:', error.message)
    alert('User deletion failed: ' + error.message)
  }
}

onMounted(() => {
  fetchUsers()
})
</script>