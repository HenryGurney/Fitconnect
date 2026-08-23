<template>
  <div class="max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-8">
      <div>
        <h2 class="text-3xl font-black text-white uppercase italic tracking-tighter">
          Match <span class="text-[#39FF14]">Lobbies</span>
        </h2>
        <p class="text-zinc-500 text-xs font-bold uppercase tracking-widest mt-1">
          Live matchmaking oversight & squad management
        </p>
      </div>

      <div class="flex items-center gap-4">
        <div class="text-right">
          <span class="text-zinc-500 text-[10px] font-black uppercase">Active Matches</span>
          <p class="text-2xl font-black text-white tabular-nums">{{ filteredLobbies.length }}</p>
        </div>
        <button 
          @click="fetchLobbies"
          class="p-3 bg-zinc-900 border border-zinc-800 rounded-xl hover:border-zinc-700 text-zinc-400 hover:text-white transition active:scale-95"
          title="Refresh Data"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Filters & Search Bar -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
      <div class="relative">
        <input 
          v-model="searchQuery" 
          type="text" 
          placeholder="Search by title, location, or sport..."
          class="w-full bg-zinc-900/80 border border-zinc-800 rounded-xl px-4 py-3 pl-10 text-sm text-white focus:border-[#39FF14] focus:ring-1 focus:ring-[#39FF14] outline-none transition placeholder:text-zinc-600"
        />
        <svg class="w-4 h-4 text-zinc-500 absolute left-3.5 top-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </div>

      <div>
        <select 
          v-model="selectedSport"
          class="w-full bg-zinc-900/80 border border-zinc-800 rounded-xl px-4 py-3 text-sm text-white focus:border-[#39FF14] outline-none transition"
        >
          <option value="">All Sports</option>
          <option v-for="sport in sportsList" :key="sport" :value="sport">{{ sport }}</option>
        </select>
      </div>

      <div>
        <select 
          v-model="selectedCapacity"
          class="w-full bg-zinc-900/80 border border-zinc-800 rounded-xl px-4 py-3 text-sm text-white focus:border-[#39FF14] outline-none transition"
        >
          <option value="">All Match Capacities</option>
          <option value="open">Open Slots Available</option>
          <option value="full">Full / Max Capacity</option>
        </select>
      </div>
    </div>

    <!-- Table Container -->
    <div class="bg-zinc-900/50 rounded-2xl border border-zinc-800 overflow-hidden shadow-2xl">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead class="bg-zinc-800/50 text-[#39FF14] text-[10px] font-black uppercase tracking-[0.2em]">
            <tr>
              <th class="p-5">Match & Sport</th>
              <th class="p-5">Venue & Time</th>
              <th class="p-5">Host Organizer</th>
              <th class="p-5 text-center">Squad Capacity</th>
              <th class="p-5">Fee / Restrictions</th>
              <th class="p-5 text-right">Actions</th>
            </tr>
          </thead>
          
          <tbody class="text-sm">
            <tr v-if="loading">
              <td colspan="6" class="p-20 text-center text-zinc-500 font-bold animate-pulse">
                RETRIEVING LIVE MATCH LOBBIES...
              </td>
            </tr>

            <tr v-else-if="filteredLobbies.length === 0">
              <td colspan="6" class="p-20 text-center text-zinc-500 font-bold">
                NO ACTIVE MATCHES MATCHING FILTER CRITERIA.
              </td>
            </tr>

            <tr 
              v-for="lobby in filteredLobbies" 
              :key="lobby.id" 
              class="border-t border-zinc-800/50 hover:bg-[#39FF14]/5 transition-colors group"
            >
              <!-- 1. Match & Sport -->
              <td class="p-5">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-xl bg-zinc-800 border border-zinc-700 flex items-center justify-center text-[#39FF14] font-black text-xs">
                    {{ (lobby.sport || '⚽').slice(0, 3).toUpperCase() }}
                  </div>
                  <div>
                    <div class="font-bold text-white group-hover:text-[#39FF14] transition-colors">
                      {{ lobby.title || 'Casual Match' }}
                    </div>
                    <div class="text-[10px] text-zinc-500 font-mono flex items-center gap-2 mt-0.5">
                      <span class="px-1.5 py-0.5 rounded bg-zinc-800 text-zinc-400 font-bold uppercase">{{ lobby.sport }}</span>
                      <span>ID: {{ String(lobby.id).slice(0, 8) }}...</span>
                    </div>
                  </div>
                </div>
              </td>

              <!-- 2. Venue & Time -->
              <td class="p-5">
                <div class="text-zinc-300 font-medium text-xs max-w-[200px] truncate" :title="lobby.location_name">
                  📍 {{ lobby.location_name || 'TBD Venue' }}
                </div>
                <div class="text-[10px] text-zinc-500 mt-1">
                  🗓️ {{ lobby.match_date || 'Upcoming' }} <span v-if="lobby.match_time">• {{ lobby.match_time }}</span>
                </div>
              </td>

              <!-- 3. Host Organizer -->
              <td class="p-5">
                <div class="flex items-center gap-2">
                  <div class="w-6 h-6 rounded-full bg-amber-400/10 border border-amber-400/30 flex items-center justify-center text-amber-400 text-[10px] font-bold">
                    👑
                  </div>
                  <div class="text-xs font-bold text-zinc-300">
                    {{ hostNames[lobby.host_id] || 'Loading host...' }}
                  </div>
                </div>
              </td>

              <!-- 4. Squad Capacity -->
              <td class="p-5 text-center">
                <div class="inline-flex flex-col items-center">
                  <div class="flex items-center gap-1.5">
                    <span class="text-xs font-bold text-white tabular-nums">
                      {{ (participantsCount[lobby.id] || 0) + 1 }} / {{ lobby.max_participants || 10 }}
                    </span>
                  </div>
                  <div class="w-20 bg-zinc-800 h-1.5 rounded-full overflow-hidden mt-1.5">
                    <div 
                      class="h-full rounded-full transition-all"
                      :class="((participantsCount[lobby.id] || 0) + 1) >= (lobby.max_participants || 10) ? 'bg-red-500' : 'bg-[#39FF14]'"
                      :style="{ width: `${Math.min(100, (((participantsCount[lobby.id] || 0) + 1) / (lobby.max_participants || 10)) * 100)}%` }"
                    ></div>
                  </div>
                </div>
              </td>

              <!-- 5. Fee / Restrictions -->
              <td class="p-5">
                <div class="flex flex-wrap gap-1.5">
                  <span class="px-2 py-0.5 rounded bg-zinc-800 text-[#39FF14] text-[10px] font-bold">
                    {{ lobby.fee_per_pax || 'Free Entry' }}
                  </span>
                  <span v-if="lobby.gender_restriction" class="px-2 py-0.5 rounded bg-zinc-800/80 text-zinc-400 text-[10px]">
                    {{ lobby.gender_restriction }}
                  </span>
                </div>
              </td>

              <!-- 6. Actions -->
              <td class="p-5 text-right">
                <div class="flex items-center justify-end gap-2">
                  <button 
                    @click="openSquadModal(lobby)"
                    class="px-3 py-1.5 rounded-xl text-[10px] font-bold uppercase bg-zinc-800 text-zinc-300 hover:text-white hover:bg-zinc-700 transition"
                  >
                    Squad Details
                  </button>
                  <button 
                    @click="deleteLobby(lobby)"
                    class="px-3 py-1.5 rounded-xl text-[10px] font-black uppercase bg-red-500/10 text-red-500 border border-red-500/20 hover:bg-red-500 hover:text-white transition active:scale-95"
                    title="Cancel & Delete Match"
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

    <!-- Squad Details Modal -->
    <div v-if="selectedLobby" class="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div class="bg-zinc-900 border border-zinc-800 rounded-3xl max-w-lg w-full p-6 shadow-2xl relative">
        <button 
          @click="selectedLobby = null" 
          class="absolute top-5 right-5 text-zinc-500 hover:text-white text-lg font-bold"
        >
          ✕
        </button>

        <div class="flex items-center gap-3 mb-4">
          <span class="text-2xl font-black text-[#39FF14]">{{ selectedLobby.sport }}</span>
          <div>
            <h3 class="text-lg font-black text-white">{{ selectedLobby.title }}</h3>
            <p class="text-xs text-zinc-500">📍 {{ selectedLobby.location_name }}</p>
          </div>
        </div>

        <div class="border-t border-zinc-800 pt-4 mb-4">
          <h4 class="text-xs font-bold text-zinc-400 uppercase tracking-wider mb-3">Approved Squad Members</h4>
          
          <div v-if="loadingSquad" class="text-center py-6 text-zinc-500 text-xs animate-pulse">
            Loading confirmed players...
          </div>
          
          <div v-else-if="squadMembers.length === 0" class="text-center py-6 text-zinc-500 text-xs">
            Only the Host organizer is currently in this match.
          </div>

          <div v-else class="space-y-2 max-h-60 overflow-y-auto pr-1">
            <div 
              v-for="member in squadMembers" 
              :key="member.id"
              class="flex items-center justify-between bg-zinc-950 p-3 rounded-xl border border-zinc-800/40"
            >
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-full bg-zinc-800 flex items-center justify-center text-[#39FF14] text-xs font-bold">
                  {{ member.name ? member.name[0].toUpperCase() : 'P' }}
                </div>
                <div>
                  <div class="text-xs font-bold text-white">{{ member.name || 'Anonymous' }}</div>
                  <div class="text-[10px] text-zinc-500">{{ member.skill || member.skill_level || 'Player' }} • {{ member.location }}</div>
                </div>
              </div>
              <span class="text-[10px] font-bold text-[#39FF14] bg-[#39FF14]/10 px-2 py-0.5 rounded">
                CONFIRMED
              </span>
            </div>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <button 
            @click="selectedLobby = null"
            class="px-5 py-2.5 bg-zinc-800 hover:bg-zinc-700 text-white rounded-xl text-xs font-bold transition"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabaseClient'

const lobbies = ref([])
const hostNames = ref({})
const participantsCount = ref({})
const loading = ref(true)

const searchQuery = ref('')
const selectedSport = ref('')
const selectedCapacity = ref('')

const selectedLobby = ref(null)
const squadMembers = ref([])
const loadingSquad = ref(false)

const sportsList = ['Futsal', 'Badminton', 'Basketball', 'Football', 'Tennis', 'Running', 'Volleyball', 'Padel']

const fetchLobbies = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('lobbies')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    lobbies.value = data || []

    // Fetch hosts and participant counts in background
    await Promise.all([
      fetchHostProfiles(lobbies.value),
      fetchParticipantsCounts(lobbies.value)
    ])
  } catch (err) {
    console.error('Error fetching lobbies:', err.message)
  } finally {
    loading.value = false
  }
}

const fetchHostProfiles = async (lobbyList) => {
  const hostIds = [...new Set(lobbyList.map(l => l.host_id).filter(Boolean))]
  if (hostIds.length === 0) return

  try {
    const { data } = await supabase
      .from('profiles')
      .select('id, name')
      .in('id', hostIds)

    if (data) {
      const map = {}
      data.forEach(p => { map[p.id] = p.name })
      hostNames.value = map
    }
  } catch (e) {
    console.error('Error fetching host profiles:', e)
  }
}

const fetchParticipantsCounts = async (lobbyList) => {
  const lobbyIds = lobbyList.map(l => l.id)
  if (lobbyIds.length === 0) return

  try {
    const { data } = await supabase
      .from('lobby_participants')
      .select('lobby_id, status')
      .in('lobby_id', lobbyIds)
      .eq('status', 'approved')

    if (data) {
      const counts = {}
      data.forEach(p => {
        counts[p.lobby_id] = (counts[p.lobby_id] || 0) + 1
      })
      participantsCount.value = counts
    }
  } catch (e) {
    console.error('Error fetching participant counts:', e)
  }
}

const filteredLobbies = computed(() => {
  return lobbies.value.filter(l => {
    // Search
    const q = searchQuery.value.toLowerCase()
    const matchesSearch = !q || 
      (l.title && l.title.toLowerCase().includes(q)) ||
      (l.sport && l.sport.toLowerCase().includes(q)) ||
      (l.location_name && l.location_name.toLowerCase().includes(q))

    // Sport filter
    const matchesSport = !selectedSport.value || l.sport === selectedSport.value

    // Capacity filter
    let matchesCap = true
    const total = (participantsCount.value[l.id] || 0) + 1
    const max = l.max_participants || 10
    if (selectedCapacity.value === 'open') {
      matchesCap = total < max
    } else if (selectedCapacity.value === 'full') {
      matchesCap = total >= max
    }

    return matchesSearch && matchesSport && matchesCap
  })
})

const openSquadModal = async (lobby) => {
  selectedLobby.value = lobby
  loadingSquad.value = true
  squadMembers.value = []

  try {
    const { data: participants } = await supabase
      .from('lobby_participants')
      .select('user_id')
      .eq('lobby_id', lobby.id)
      .eq('status', 'approved')

    if (participants && participants.length > 0) {
      const userIds = participants.map(p => p.user_id)
      const { data: profiles } = await supabase
        .from('profiles')
        .select('*')
        .in('id', userIds)

      squadMembers.value = profiles || []
    }
  } catch (e) {
    console.error('Error loading squad:', e)
  } finally {
    loadingSquad.value = false
  }
}

const deleteLobby = async (lobby) => {
  const confirmed = confirm(`Are you sure you want to cancel and delete "${lobby.title}"? This cannot be undone.`)
  if (!confirmed) return

  try {
    // 1. Delete associated participants
    await supabase.from('lobby_participants').delete().eq('lobby_id', lobby.id)
    
    // 2. Delete lobby
    const { error } = await supabase.from('lobbies').delete().eq('id', lobby.id)
    if (error) throw error

    alert("Match lobby successfully deleted.")
    await fetchLobbies()
  } catch (e) {
    console.error('Error deleting lobby:', e.message)
    alert("Failed to delete lobby: " + e.message)
  }
}

onMounted(() => {
  fetchLobbies()
})
</script>
