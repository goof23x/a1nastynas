import axios from 'axios'

const API_URL = 'http://localhost:8080/api'

const api = axios.create({
  baseURL: API_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// Add request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Add response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Clear token and redirect to login
      localStorage.removeItem('token')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export const storageApi = {
  // ZFS Pool Management
  listPools: () => api.get('/storage/pools'),
  createPool: (name, devices, raidType) => api.post('/storage/pools', { name, devices, raidType }),
  getPoolStatus: (name) => api.get(`/storage/pools/${name}/status`),
  destroyPool: (name) => api.delete(`/storage/pools/${name}`),
  getAvailableDevices: () => api.get('/storage/devices'),

  // File Management
  listFiles: (path) => api.get(`/storage/files/${path}`),
  uploadFile: (path, file) => {
    const formData = new FormData();
    formData.append('file', file);
    return api.post(`/storage/files/${path}`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  },
  downloadFile: (path) => api.get(`/storage/files/${path}/download`, { responseType: 'blob' }),
  deleteItem: (path) => api.delete(`/storage/files/${path}`),
  createDirectory: (path) => api.post(`/storage/directories/${path}`),
  moveItem: (source, destination) => api.post('/storage/move', { source, destination }),
  copyItem: (source, destination) => api.post('/storage/copy', { source, destination }),
}

export const dockerApi = {
  getContainers: () => api.get('/docker/containers'),
  startContainer: (id) => api.post(`/docker/containers/${id}/start`),
  stopContainer: (id) => api.post(`/docker/containers/${id}/stop`),
  getContainerLogs: (id) => api.get(`/docker/containers/${id}/logs`),
}

export const systemApi = {
  getSystemInfo: () => api.get('/system/info'),
  getSystemLogs: () => api.get('/system/logs'),
  getResourceUsage: () => api.get('/system/resources'),
}

export const authApi = {
  login: async (username, password) => {
    const response = await api.post('/auth/login', { username, password })
    const { token } = response.data
    localStorage.setItem('token', token)
    return response.data
  },
  logout: () => {
    localStorage.removeItem('token')
  },
  isAuthenticated: () => {
    return !!localStorage.getItem('token')
  },
}

export default api 