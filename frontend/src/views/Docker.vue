<template>
  <div class="space-y-6">
    <!-- Container List -->
    <div class="bg-white shadow rounded-lg p-6">
      <div class="flex justify-between items-center mb-4">
        <h2 class="text-lg font-medium text-gray-900">Docker Containers</h2>
        <button
          @click="refreshContainers"
          class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Refresh
        </button>
      </div>

      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Image
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="container in containers" :key="container.Id">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm font-medium text-gray-900">
                  {{ container.Names[0].replace('/', '') }}
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  :class="[
                    container.State === 'running' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800',
                    'px-2 inline-flex text-xs leading-5 font-semibold rounded-full'
                  ]"
                >
                  {{ container.State }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ container.Image }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <div class="flex space-x-2">
                  <button
                    v-if="container.State !== 'running'"
                    @click="startContainer(container.Id)"
                    class="text-indigo-600 hover:text-indigo-900"
                  >
                    Start
                  </button>
                  <button
                    v-if="container.State === 'running'"
                    @click="stopContainer(container.Id)"
                    class="text-red-600 hover:text-red-900"
                  >
                    Stop
                  </button>
                  <button
                    @click="showLogs(container.Id)"
                    class="text-gray-600 hover:text-gray-900"
                  >
                    Logs
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Logs Modal -->
    <div v-if="showLogsModal" class="fixed z-10 inset-0 overflow-y-auto">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>

        <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-4xl sm:w-full">
          <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div class="mt-3 text-center sm:mt-0 sm:text-left w-full">
                <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
                  Container Logs
                </h3>
                <div class="mt-2">
                  <pre class="bg-gray-50 p-4 rounded-lg text-sm text-gray-900 overflow-auto max-h-96">{{ containerLogs }}</pre>
                </div>
              </div>
            </div>
          </div>
          <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              @click="closeLogsModal"
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { dockerApi } from '@/services/api'

const containers = ref([])
const showLogsModal = ref(false)
const containerLogs = ref('')

const fetchContainers = async () => {
  try {
    const response = await dockerApi.getContainers()
    containers.value = response.data.containers
  } catch (error) {
    console.error('Error fetching containers:', error)
  }
}

const startContainer = async (id) => {
  try {
    await dockerApi.startContainer(id)
    await fetchContainers()
  } catch (error) {
    console.error('Error starting container:', error)
  }
}

const stopContainer = async (id) => {
  try {
    await dockerApi.stopContainer(id)
    await fetchContainers()
  } catch (error) {
    console.error('Error stopping container:', error)
  }
}

const showLogs = async (id) => {
  try {
    const response = await dockerApi.getContainerLogs(id)
    containerLogs.value = response.data.logs
    showLogsModal.value = true
  } catch (error) {
    console.error('Error fetching container logs:', error)
  }
}

const closeLogsModal = () => {
  showLogsModal.value = false
  containerLogs.value = ''
}

const refreshContainers = () => {
  fetchContainers()
}

onMounted(fetchContainers)
</script> 