<template>
  <div class="space-y-8">
    <div class="flex flex-col md:flex-row gap-4 mb-4">
      <button class="btn btn-primary flex-1 text-lg py-6" @click="addContainer">
        <TablerIcon name="plus" class="w-6 h-6 mr-2" /> Add Container
      </button>
      <a href="/portainer" target="_blank" class="btn btn-info flex-1 text-lg py-6">
        <TablerIcon name="external-link" class="w-6 h-6 mr-2" /> Open in Portainer
      </a>
    </div>
    <div class="bg-white rounded-lg shadow p-6">
      <h3 class="text-lg font-bold mb-4 text-tiffany">Docker Containers</h3>
      <table class="table w-full">
        <thead>
          <tr>
            <th>Name</th>
            <th>Status</th>
            <th>Image</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="container in containers" :key="container.Id">
            <td>{{ container.Names[0].replace('/', '') }}</td>
            <td>
              <span :class="['badge', container.State === 'running' ? 'badge-success' : 'badge-error']">{{ container.State }}</span>
            </td>
            <td>{{ container.Image }}</td>
            <td>
              <div class="flex gap-2">
                <button class="btn btn-xs btn-ghost text-green-600" @click="startContainer(container.Id)">
                  <TablerIcon name="player-play" />
                </button>
                <button class="btn btn-xs btn-ghost text-yellow-600" @click="restartContainer(container.Id)">
                  <TablerIcon name="refresh" />
                </button>
                <button class="btn btn-xs btn-ghost text-red-600" @click="stopContainer(container.Id)">
                  <TablerIcon name="player-stop" />
                </button>
                <button class="btn btn-xs btn-ghost text-tiffany" @click="showLogs(container.Id)">
                  <TablerIcon name="file-text" />
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <!-- Logs Modal -->
    <dialog v-if="showLogsModal" class="modal modal-open">
      <form method="dialog" class="modal-box" @submit.prevent="closeLogsModal">
        <h3 class="font-bold text-lg mb-4">Container Logs</h3>
        <pre class="bg-base-200 p-4 rounded-lg text-sm text-base-content overflow-auto max-h-96">{{ containerLogs }}</pre>
        <div class="modal-action">
          <button class="btn btn-primary" type="submit">Close</button>
        </div>
      </form>
    </dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import TablerIcon from '../components/TablerIcon.vue'
// import { dockerApi } from '@/services/api' // Uncomment and use real API

const containers = ref([])
const showLogsModal = ref(false)
const containerLogs = ref('')

const fetchContainers = async () => {
  // TODO: Replace with real API call
  containers.value = [
    { Id: '1', Names: ['/nginx'], State: 'running', Image: 'nginx:latest' },
    { Id: '2', Names: ['/db'], State: 'exited', Image: 'postgres:14' }
  ]
}

const addContainer = () => {
  window.$toast({ message: 'Add Container clicked', type: 'info', icon: 'ti ti-plus' })
}
const startContainer = (id) => {
  window.$toast({ message: `Start container ${id}`, type: 'success', icon: 'ti ti-player-play' })
}
const stopContainer = (id) => {
  window.$toast({ message: `Stop container ${id}`, type: 'info', icon: 'ti ti-player-stop' })
}
const restartContainer = (id) => {
  window.$toast({ message: `Restart container ${id}`, type: 'info', icon: 'ti ti-refresh' })
}
const showLogs = (id) => {
  containerLogs.value = `Logs for container ${id}...` // TODO: Replace with real logs
  showLogsModal.value = true
}
const closeLogsModal = () => {
  showLogsModal.value = false
  containerLogs.value = ''
}

onMounted(fetchContainers)
</script> 