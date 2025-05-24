<template>
  <div class="space-y-6">
    <!-- System Information -->
    <div class="bg-white shadow rounded-lg p-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">System Information</h2>
      <dl class="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
        <div v-for="(value, key) in systemInfo" :key="key" class="sm:col-span-1">
          <dt class="text-sm font-medium text-gray-500">{{ formatKey(key) }}</dt>
          <dd class="mt-1 text-sm text-gray-900">{{ value }}</dd>
        </div>
      </dl>
    </div>

    <!-- Resource Usage -->
    <div class="bg-white shadow rounded-lg p-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Resource Usage</h2>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <!-- CPU Usage -->
        <div class="bg-gray-50 p-4 rounded-lg">
          <h3 class="text-sm font-medium text-gray-500">CPU Usage</h3>
          <div class="mt-2">
            <div class="relative pt-1">
              <div class="flex mb-2 items-center justify-between">
                <div>
                  <span class="text-xs font-semibold inline-block py-1 px-2 uppercase rounded-full text-indigo-600 bg-indigo-200">
                    {{ Math.round(resourceUsage.cpu?.usage || 0) }}%
                  </span>
                </div>
              </div>
              <div class="overflow-hidden h-2 mb-4 text-xs flex rounded bg-indigo-200">
                <div
                  :style="{ width: `${resourceUsage.cpu?.usage || 0}%` }"
                  class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-indigo-500"
                ></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Memory Usage -->
        <div class="bg-gray-50 p-4 rounded-lg">
          <h3 class="text-sm font-medium text-gray-500">Memory Usage</h3>
          <div class="mt-2">
            <div class="relative pt-1">
              <div class="flex mb-2 items-center justify-between">
                <div>
                  <span class="text-xs font-semibold inline-block py-1 px-2 uppercase rounded-full text-green-600 bg-green-200">
                    {{ Math.round(resourceUsage.memory?.percent || 0) }}%
                  </span>
                </div>
              </div>
              <div class="overflow-hidden h-2 mb-4 text-xs flex rounded bg-green-200">
                <div
                  :style="{ width: `${resourceUsage.memory?.percent || 0}%` }"
                  class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-green-500"
                ></div>
              </div>
            </div>
            <div class="text-xs text-gray-500 mt-2">
              {{ formatBytes(resourceUsage.memory?.used || 0) }} / {{ formatBytes(resourceUsage.memory?.total || 0) }}
            </div>
          </div>
        </div>

        <!-- Disk Usage -->
        <div class="bg-gray-50 p-4 rounded-lg">
          <h3 class="text-sm font-medium text-gray-500">Disk Usage</h3>
          <div class="mt-2">
            <div class="relative pt-1">
              <div class="flex mb-2 items-center justify-between">
                <div>
                  <span class="text-xs font-semibold inline-block py-1 px-2 uppercase rounded-full text-red-600 bg-red-200">
                    {{ Math.round(resourceUsage.disk?.percent || 0) }}%
                  </span>
                </div>
              </div>
              <div class="overflow-hidden h-2 mb-4 text-xs flex rounded bg-red-200">
                <div
                  :style="{ width: `${resourceUsage.disk?.percent || 0}%` }"
                  class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-red-500"
                ></div>
              </div>
            </div>
            <div class="text-xs text-gray-500 mt-2">
              {{ formatBytes(resourceUsage.disk?.used || 0) }} / {{ formatBytes(resourceUsage.disk?.total || 0) }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- System Logs -->
    <div class="bg-white shadow rounded-lg p-6">
      <div class="flex justify-between items-center mb-4">
        <h2 class="text-lg font-medium text-gray-900">System Logs</h2>
        <button
          @click="refreshLogs"
          class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Refresh
        </button>
      </div>
      <div class="bg-gray-50 rounded-lg p-4">
        <pre class="text-sm text-gray-900 overflow-auto max-h-96">{{ systemLogs.join('\n') }}</pre>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { systemApi } from '@/services/api'

const systemInfo = ref({})
const resourceUsage = ref({})
const systemLogs = ref([])

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
  } catch (error) {
    console.error('Error fetching system data:', error)
  }
}

const refreshLogs = () => {
  fetchData()
}

onMounted(() => {
  fetchData()
  // Refresh data every 30 seconds
  setInterval(fetchData, 30000)
})
</script> 