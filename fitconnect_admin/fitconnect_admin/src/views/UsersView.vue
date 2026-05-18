<template>
  <div class="max-w-7xl mx-auto">
    <div class="flex justify-between items-end mb-8">
      <div>
        <h2 class="text-3xl font-black text-white uppercase italic tracking-tighter">
          User <span class="text-neon-green">Management</span>
        </h2>
        <p class="text-zinc-500 text-xs font-bold uppercase tracking-widest mt-1">
          Review and moderate FitConnect athletes
        </p>
      </div>
      <div class="text-right">
        <span class="text-zinc-500 text-[10px] font-black uppercase">Total Athletes</span>
        <p class="text-2xl font-black text-white">{{ users.length }}</p>
      </div>
    </div>

    <div class="bg-zinc-900/50 rounded-2xl border border-zinc-800 overflow-hidden shadow-2xl">
      <table class="w-full text-left border-collapse">
        <thead class="bg-zinc-800/50 text-neon-green text-[10px] font-black uppercase tracking-[0.2em]">
          <tr>
            <th class="p-5">Athlete Info</th>
            <th class="p-5">Primary Sport</th>
            <th class="p-5">Skill Level</th>
            <th class="p-4 text-center">Status</th>
            <th class="p-5 text-right">Actions</th>
          </tr>
        </thead>
        
        <tbody class="text-sm">
          <tr v-if="loading">
            <td colspan="5" class="p-20 text-center text-zinc-500 font-bold animate-pulse">
              INITIALIZING DATA...
            </td>
          </tr>

          <tr v-else-if="users.length === 0">
            <td colspan="5" class="p-20 text-center text-zinc-500 font-bold">
              NO ATHLETES FOUND IN DATABASE.
            </td>
          </tr>

          <tr 
            v-for="user in users" 
            :key="user.id" 
            class="border-t border-zinc-800/50 hover:bg-neon-green/5 transition-colors group"
          >
            <td class="p-5">
              <div class="flex items-center gap-4">
                <div class="w-10 h-10 rounded-full bg-zinc-800 border border-zinc-700 flex items-center justify-center text-neon-green font-black">
                  {{ user.name ? user.name[0].toUpperCase() : '?' }}
                </div>
                <div>
                  <div class="font-bold text-white group-hover:text-neon-green transition-colors">
                    {{ user.name || 'Anonymous User' }}
                  </div>
                  <div class="text-[10px] text-zinc-500 font-mono">{{ user.email }}</div>
                </div>
              </div>
            </td>

            <td class="p-5">
              <span class="px-2 py-1 rounded bg-zinc-800 text-zinc-300 text-[10px] font-bold uppercase tracking-wider">
                {{ user.sport || 'Multi-Sport' }}
              </span>
            </td>

            <td class="p-5 font-medium text-zinc-400">
              {{ user.skill_level || 'Beginner' }}
            </td>

            <td class="p-5 text-center">
              <div class="w-2 h-2 rounded-full bg-neon-green mx-auto shadow-[0_0_8px_#39FF14]"></div>
            </td>

            <td class="p-5 text-right">
              <button 
                @click="suspendUser(user.id)"
                class="bg-red-500/10 text-red-500 border border-red-500/20 px-4 py-2 rounded-xl text-[10px] font-black uppercase hover:bg-red-500 hover:text-white transition-all active:scale-95"
              >
                Suspend
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabaseClient'

const users = ref([])
const loading = ref(true)

const fetchUsers = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('is_admin', false) // 1. FILTER: Don't show admins
      .order('name', { ascending: true }) // 2. SORT: Alphabetical

    if (error) throw error
    if (data) users.value = data
  } catch (error) {
    console.error('Error fetching users:', error.message)
    alert('Failed to load users from database.')
  } finally {
    loading.value = false
  }
}

const suspendUser = async (userId) => {
  const confirmed = confirm("Are you sure you want to suspend this athlete's access?")
  if (confirmed) {
    // For your Master's project logic: 
    // You could update a 'status' column in Supabase here.
    alert(`User ${userId} suspension logic triggered.`)
  }
}

onMounted(() => {
  fetchUsers()
})
</script>

<style scoped>
/* Optional: Custom scrollbar for the table if it gets long */
::-webkit-scrollbar {
  width: 6px;
}
::-webkit-scrollbar-thumb {
  background: #27272a;
  border-radius: 10px;
}
</style>