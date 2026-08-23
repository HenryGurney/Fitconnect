<template>
  <div class="max-w-7xl mx-auto">
    <!-- Header -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-8">
      <div>
        <h2 class="text-3xl font-black text-white uppercase italic tracking-tighter">
          Incident <span class="text-red-500">Reports</span>
        </h2>
        <p class="text-zinc-500 text-xs font-bold uppercase tracking-widest mt-1">
          Review community reports, no-shows, and dispute moderation
        </p>
      </div>

      <div class="flex items-center gap-4">
        <div class="text-right">
          <span class="text-zinc-500 text-[10px] font-black uppercase">Total Reports</span>
          <p class="text-2xl font-black text-white tabular-nums">{{ reports.length }}</p>
        </div>
        <button 
          @click="fetchReports"
          class="p-3 bg-zinc-900 border border-zinc-800 rounded-xl hover:border-zinc-700 text-zinc-400 hover:text-white transition active:scale-95"
          title="Refresh Data"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Filters & Search -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
      <div class="relative">
        <input 
          v-model="searchQuery" 
          type="text" 
          placeholder="Search by reason, notes, or athlete..."
          class="w-full bg-zinc-900/80 border border-zinc-800 rounded-xl px-4 py-3 pl-10 text-sm text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition placeholder:text-zinc-600"
        />
        <svg class="w-4 h-4 text-zinc-500 absolute left-3.5 top-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </div>

      <div>
        <select 
          v-model="selectedReason"
          class="w-full bg-zinc-900/80 border border-zinc-800 rounded-xl px-4 py-3 text-sm text-white focus:border-red-500 outline-none transition"
        >
          <option value="">All Violation Types</option>
          <option value="No-Show">No-Show / Unattended Match</option>
          <option value="Last-Minute">Last-Minute Cancellation</option>
          <option value="Unsportsmanlike">Unsportsmanlike / Toxic Conduct</option>
          <option value="Payment">Payment Refusal / Fee Evasion</option>
          <option value="Harassment">Harassment / Inappropriate Content</option>
        </select>
      </div>
    </div>

    <!-- Table Container -->
    <div class="bg-zinc-900/50 rounded-2xl border border-zinc-800 overflow-hidden shadow-2xl">
      <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
          <thead class="bg-zinc-800/50 text-red-400 text-[10px] font-black uppercase tracking-[0.2em]">
            <tr>
              <th class="p-5">Reported Athlete</th>
              <th class="p-5">Violation / Reason</th>
              <th class="p-5">Details & Notes</th>
              <th class="p-5 text-center">Penalty Applied</th>
              <th class="p-5">Reported At</th>
              <th class="p-5 text-right">Moderation Actions</th>
            </tr>
          </thead>
          
          <tbody class="text-sm">
            <tr v-if="loading">
              <td colspan="6" class="p-20 text-center text-zinc-500 font-bold animate-pulse">
                SCANNING INCIDENT LOGS...
              </td>
            </tr>

            <tr v-else-if="filteredReports.length === 0">
              <td colspan="6" class="p-20 text-center text-zinc-500 font-bold">
                NO INCIDENT REPORTS RECORDED. COMMUNITY HEALTHY 🌟
              </td>
            </tr>

            <tr 
              v-for="report in filteredReports" 
              :key="report.id" 
              class="border-t border-zinc-800/50 hover:bg-red-500/5 transition-colors group"
            >
              <!-- 1. Reported Athlete -->
              <td class="p-5">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-full bg-zinc-800 border border-zinc-700 flex items-center justify-center text-red-400 font-bold text-sm">
                    {{ (userProfiles[report.reported_user_id]?.name || '?').slice(0, 1).toUpperCase() }}
                  </div>
                  <div>
                    <div class="font-bold text-white group-hover:text-red-400 transition-colors">
                      {{ userProfiles[report.reported_user_id]?.name || 'Unknown Athlete' }}
                    </div>
                    <div class="text-[10px] text-zinc-500 font-mono">
                      Reliability: 
                      <span :class="(userProfiles[report.reported_user_id]?.reliability_score ?? 100) < 75 ? 'text-red-400' : 'text-[#39FF14]'">
                        {{ userProfiles[report.reported_user_id]?.reliability_score ?? 100 }}%
                      </span>
                    </div>
                  </div>
                </div>
              </td>

              <!-- 2. Violation / Reason -->
              <td class="p-5">
                <div class="flex items-center gap-2">
                  <span class="px-2.5 py-1 rounded bg-red-500/10 text-red-400 border border-red-500/20 text-xs font-bold">
                    {{ report.reason }}
                  </span>
                </div>
                <div v-if="report.lobby_id" class="text-[10px] text-zinc-500 font-mono mt-1">
                  Match: {{ String(report.lobby_id).slice(0, 8) }}...
                </div>
              </td>

              <!-- 3. Details & Notes -->
              <td class="p-5 max-w-[220px]">
                <p class="text-zinc-300 text-xs truncate" :title="report.notes || 'No extra notes provided.'">
                  {{ report.notes || 'No extra notes provided by reporter.' }}
                </p>
                <p class="text-[10px] text-zinc-500 mt-0.5">
                  Filed by: {{ userProfiles[report.reporter_id]?.name || 'Teammate / Host' }}
                </p>
              </td>

              <!-- 4. Penalty Applied -->
              <td class="p-5 text-center">
                <span class="px-2.5 py-1 rounded bg-zinc-800 text-red-400 text-xs font-black">
                  -{{ report.penalty_applied ?? 10 }}%
                </span>
              </td>

              <!-- 5. Reported At -->
              <td class="p-5 text-zinc-400 text-xs">
                {{ formatDate(report.created_at) }}
              </td>

              <!-- 6. Moderation Actions -->
              <td class="p-5 text-right">
                <div class="flex items-center justify-end gap-2">
                  <button 
                    @click="forgiveReport(report)"
                    class="px-3 py-1.5 rounded-xl text-[10px] font-bold uppercase bg-[#39FF14]/10 text-[#39FF14] border border-[#39FF14]/20 hover:bg-[#39FF14] hover:text-black transition active:scale-95"
                    title="Refund Penalty and Restore Score"
                  >
                    Forgive (+{{ report.penalty_applied ?? 10 }}%)
                  </button>
                  <button 
                    @click="dismissReport(report)"
                    class="px-3 py-1.5 rounded-xl text-[10px] font-bold uppercase bg-zinc-800 text-zinc-400 hover:text-white hover:bg-zinc-700 transition"
                    title="Dismiss and remove report record"
                  >
                    Dismiss
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

const reports = ref([])
const userProfiles = ref({})
const loading = ref(true)

const searchQuery = ref('')
const selectedReason = ref('')

const fetchReports = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('reports')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      console.warn("Reports table not created yet or empty:", error.message)
      reports.value = []
    } else {
      reports.value = data || []
      await fetchUserProfiles(reports.value)
    }
  } catch (err) {
    console.error('Error fetching reports:', err.message)
  } finally {
    loading.value = false
  }
}

const fetchUserProfiles = async (reportList) => {
  const userIds = [
    ...new Set([
      ...reportList.map(r => r.reported_user_id),
      ...reportList.map(r => r.reporter_id)
    ].filter(Boolean))
  ]

  if (userIds.length === 0) return

  try {
    const { data } = await supabase
      .from('profiles')
      .select('id, name, reliability_score')
      .in('id', userIds)

    if (data) {
      const map = {}
      data.forEach(p => { map[p.id] = p })
      userProfiles.value = map
    }
  } catch (e) {
    console.error('Error fetching user profiles for reports:', e)
  }
}

const filteredReports = computed(() => {
  return reports.value.filter(r => {
    const q = searchQuery.value.toLowerCase()
    const reportedName = userProfiles.value[r.reported_user_id]?.name?.toLowerCase() || ''
    const reasonText = (r.reason || '').toLowerCase()
    const notesText = (r.notes || '').toLowerCase()

    const matchesSearch = !q || 
      reportedName.includes(q) || 
      reasonText.includes(q) || 
      notesText.includes(q)

    const matchesReason = !selectedReason.value || (r.reason && r.reason.includes(selectedReason.value))

    return matchesSearch && matchesReason
  })
})

const formatDate = (dateStr) => {
  if (!dateStr) return 'Recent'
  try {
    const d = new Date(dateStr)
    return `${d.toLocaleDateString()} ${d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`
  } catch {
    return dateStr
  }
}

const forgiveReport = async (report) => {
  const penalty = report.penalty_applied ?? 10
  const confirmed = confirm(`Forgive this report and restore +${penalty}% reliability score to the athlete?`)
  if (!confirmed) return

  try {
    // 1. Restore reliability score
    const targetUserId = report.reported_user_id
    const currentScore = userProfiles.value[targetUserId]?.reliability_score ?? 100
    const newScore = Math.min(100, currentScore + penalty)

    await supabase
      .from('profiles')
      .update({ reliability_score: newScore })
      .eq('id', targetUserId)

    // 2. Delete report record
    await supabase.from('reports').delete().eq('id', report.id)

    alert(`Incident forgiven. Athlete score restored to ${newScore}%.`)
    await fetchReports()
  } catch (e) {
    console.error('Error forgiving report:', e.message)
    alert("Operation failed: " + e.message)
  }
}

const dismissReport = async (report) => {
  const confirmed = confirm("Dismiss this report record without changing the athlete's current score?")
  if (!confirmed) return

  try {
    const { error } = await supabase.from('reports').delete().eq('id', report.id)
    if (error) throw error

    await fetchReports()
  } catch (e) {
    console.error('Error dismissing report:', e.message)
    alert("Failed to dismiss report: " + e.message)
  }
}

onMounted(() => {
  fetchReports()
})
</script>
