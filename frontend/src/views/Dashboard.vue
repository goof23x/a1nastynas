<template>
  <div class="space-y-6">
    <!-- System Overview -->
    <div class="bg-white shadow rounded-lg p-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">System Overview</h2>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div v-for="(info, key) in systemInfo" :key="key" class="bg-gray-50 p-4 rounded-lg">
          <div class="text-sm font-medium text-gray-500">{{ key }}</div>
          <div class="mt-1 text-lg font-semibold text-gray-900">{{ info }}</div>
        </div>
      </div>
    </div>

    <!-- Resource Usage -->
    <div class="bg-white shadow rounded-lg p-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Resource Usage</h2>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <!-- CPU Usage -->
        <div class="bg-gray-50 p-4 rounded-lg">
          <div class="text-sm font-medium text-gray-500">CPU Usage</div>
          <div class="mt-1">
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
          <div class="text-sm font-medium text-gray-500">Memory Usage</div>
          <div class="mt-1">
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
          </div>
        </div>

        <!-- Disk Usage -->
        <div class="bg-gray-50 p-4 rounded-lg">
          <div class="text-sm font-medium text-gray-500">Disk Usage</div>
          <div class="mt-1">
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
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Activity -->
    <div class="bg-white shadow rounded-lg p-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Recent Activity</h2>
      <div class="flow-root">
        <ul role="list" class="-mb-8">
          <li v-for="(log, index) in systemLogs" :key="index">
            <div class="relative pb-8">
              <span
                v-if="index !== systemLogs.length - 1"
                class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200"
                aria-hidden="true"
              ></span>
              <div class="relative flex space-x-3">
                <div>
                  <span class="h-8 w-8 rounded-full bg-gray-400 flex items-center justify-center ring-8 ring-white">
                    <svg class="h-5 w-5 text-white" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
                    </svg>
                  </span>
                </div>
                <div class="min-w-0 flex-1 pt-1.5 flex justify-between space-x-4">
                  <div>
                    <p class="text-sm text-gray-500">{{ log }}</p>
                  </div>
                </div>
              </div>
            </div>
          </li>
        </ul>
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
    console.error('Error fetching dashboard data:', error)
  }
}

onMounted(() => {
  fetchData()
  // Refresh data every 30 seconds
  setInterval(fetchData, 30000)
})
</script> 