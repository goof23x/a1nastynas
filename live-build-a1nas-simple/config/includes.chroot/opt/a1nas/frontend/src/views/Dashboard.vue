<template>
  <div class="space-y-8">
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <!-- Storage Widget -->
      <div class="bg-white rounded-lg shadow p-6 flex flex-col items-center">
        <TablerIcon name="database" class="w-8 h-8 text-tiffany mb-2" />
        <div class="text-2xl font-bold">{{ storage.used }} / {{ storage.total }} TB</div>
        <div class="text-sm text-gray-500">Storage Used</div>
      </div>
      <!-- CPU Widget -->
      <div class="bg-white rounded-lg shadow p-6 flex flex-col items-center">
        <TablerIcon name="cpu" class="w-8 h-8 text-tiffany mb-2" />
        <div class="text-2xl font-bold">{{ cpu.usage }}%</div>
        <div class="text-sm text-gray-500">CPU Usage</div>
      </div>
      <!-- Network Widget -->
      <div class="bg-white rounded-lg shadow p-6 flex flex-col items-center">
        <TablerIcon name="network" class="w-8 h-8 text-tiffany mb-2" />
        <div class="text-2xl font-bold">{{ network.speed }} Mbps</div>
        <div class="text-sm text-gray-500">Network</div>
      </div>
      <!-- Recent Activity Widget -->
      <div class="bg-white rounded-lg shadow p-6 flex flex-col items-center">
        <TablerIcon name="activity" class="w-8 h-8 text-tiffany mb-2" />
        <div class="text-2xl font-bold">{{ recentActivity.length }}</div>
        <div class="text-sm text-gray-500">Recent Activity</div>
      </div>
    </div>
    <div class="flex flex-col md:flex-row gap-4 mt-8">
      <button class="btn btn-primary flex-1 text-lg py-6" @click="addStorage">
        <TablerIcon name="database-plus" class="w-6 h-6 mr-2" /> Add Storage
      </button>
      <button class="btn btn-primary flex-1 text-lg py-6" @click="addUser">
        <TablerIcon name="user-plus" class="w-6 h-6 mr-2" /> Add User
      </button>
    </div>
    <div class="bg-white rounded-lg shadow p-6 mt-8">
      <h3 class="text-lg font-bold mb-4 text-tiffany">Recent Activity</h3>
      <ul class="divide-y divide-base-200">
        <li v-for="(item, i) in recentActivity" :key="i" class="py-2 flex items-center gap-2">
          <TablerIcon :name="item.icon" class="w-5 h-5 text-tiffany" />
          <span>{{ item.text }}</span>
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import TablerIcon from '../components/TablerIcon.vue'

const storage = ref({ used: 0, total: 0 })
const cpu = ref({ usage: 0 })
const network = ref({ speed: 0 })
const recentActivity = ref([])

const fetchDashboard = async () => {
  // TODO: Replace with real API calls
  storage.value = { used: 4.2, total: 8 }
  cpu.value = { usage: 23 }
  network.value = { speed: 940 }
  recentActivity.value = [
    { icon: 'user-plus', text: 'User admin created' },
    { icon: 'database-plus', text: 'Pool "tank" added' },
    { icon: 'file-upload', text: 'File report.pdf uploaded' },
    { icon: 'settings', text: 'Settings updated' }
  ]
}

const addStorage = () => {
  // TODO: Open add storage modal
  window.$toast({ message: 'Add Storage clicked', type: 'info', icon: 'ti ti-database-plus' })
}
const addUser = () => {
  // TODO: Open add user modal
  window.$toast({ message: 'Add User clicked', type: 'info', icon: 'ti ti-user-plus' })
}

onMounted(fetchDashboard)
</script> 