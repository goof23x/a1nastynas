<template>
  <div class="space-y-8">
    <div class="flex flex-col md:flex-row gap-4 mb-4">
      <button class="btn btn-primary flex-1 text-lg py-6" @click="runDiagnostics">
        <TablerIcon name="activity" class="w-6 h-6 mr-2" /> Run Diagnostics
      </button>
    </div>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <!-- System Info Card -->
      <div class="bg-white rounded-lg shadow p-6 flex flex-col items-center">
        <TablerIcon name="info-circle" class="w-8 h-8 text-tiffany mb-2" />
        <div class="text-lg font-bold mb-1">System Info</div>
        <ul class="text-sm text-gray-500 w-full">
          <li v-for="(value, key) in systemInfo" :key="key" class="flex justify-between"><span>{{ formatKey(key) }}</span><span>{{ value }}</span></li>
        </ul>
      </div>
      <!-- Resource Usage Card -->
      <div class="bg-white rounded-lg shadow p-6 flex flex-col items-center">
        <TablerIcon name="cpu" class="w-8 h-8 text-tiffany mb-2" />
        <div class="text-lg font-bold mb-1">Resource Usage</div>
        <ul class="text-sm text-gray-500 w-full">
          <li>CPU: <span class="font-bold">{{ resourceUsage.cpu?.usage || 0 }}%</span></li>
          <li>Memory: <span class="font-bold">{{ formatBytes(resourceUsage.memory?.used || 0) }} / {{ formatBytes(resourceUsage.memory?.total || 0) }}</span></li>
          <li>Disk: <span class="font-bold">{{ formatBytes(resourceUsage.disk?.used || 0) }} / {{ formatBytes(resourceUsage.disk?.total || 0) }}</span></li>
        </ul>
      </div>
      <!-- Logs Card -->
      <div class="bg-white rounded-lg shadow p-6 flex flex-col items-center">
        <TablerIcon name="file-text" class="w-8 h-8 text-tiffany mb-2" />
        <div class="text-lg font-bold mb-1">System Logs</div>
        <pre class="bg-base-200 rounded-lg p-2 w-full text-xs max-h-40 overflow-auto">{{ systemLogs.slice(0, 20).join('\n') }}</pre>
        <button class="btn btn-xs btn-ghost mt-2" @click="refreshLogs"><TablerIcon name="refresh" class="w-4 h-4" /> Refresh</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { systemApi } from '@/services/api'
import TablerIcon from '../components/TablerIcon.vue'

const systemInfo = ref({})
const resourceUsage = ref({})
const systemLogs = ref([])

const dockerInstalled = ref(false)
const installingDocker = ref(false)

const checkDocker = async () => {
  try {
    const res = await systemApi.checkDocker()
    dockerInstalled.value = res.data.installed
  } catch (e) {
    dockerInstalled.value = false
  }
}

const installDocker = async () => {
  installingDocker.value = true
  try {
    await systemApi.installDocker()
    dockerInstalled.value = true
    window.$toast({ message: 'Docker installed successfully!', type: 'success', icon: 'ti ti-brand-docker' })
  } catch (e) {
    window.$toast({ message: 'Failed to install Docker', type: 'error', icon: 'ti ti-alert-triangle' })
  } finally {
    installingDocker.value = false
  }
}

const formatKey = (key) => {
  return key
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, (str) => str.toUpperCase())
}

const formatBytes = (bytes) => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`
}

const fetchData = async () => {
  try {
    const [infoRes, resourcesRes, logsRes] = await Promise.all([
      systemApi.getSystemInfo(),
      systemApi.getResourceUsage(),
      systemApi.getSystemLogs()
    ])
    
    systemInfo.value = infoRes.data
    resourceUsage.value = resourcesRes.data
    systemLogs.value = logsRes.data.logs
    await checkDocker()
  } catch (error) {
    console.error('Error fetching system data:', error)
  }
}

const refreshLogs = () => {
  fetchData()
}

const runDiagnostics = () => {
  window.$toast({ message: 'Diagnostics started', type: 'info', icon: 'ti ti-activity' })
  // TODO: Call diagnostics API
}

onMounted(() => {
  fetchData()
  // Refresh data every 30 seconds
  setInterval(fetchData, 30000)
})
</script> 