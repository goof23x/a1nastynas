<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between mb-4">
      <h2 class="text-2xl font-bold text-tiffany">Users & Groups</h2>
      <div class="tabs tabs-boxed bg-base-200">
        <a :class="['tab', tab === 'users' ? 'tab-active' : '']" @click="tab = 'users'">Users</a>
        <a :class="['tab', tab === 'groups' ? 'tab-active' : '']" @click="tab = 'groups'">Groups</a>
      </div>
    </div>

    <!-- Users Tab -->
    <div v-if="tab === 'users'">
      <div class="flex justify-end mb-2">
        <button class="btn btn-primary" @click="openUserModal()">
          <TablerIcon name="user-plus" class="w-5 h-5 mr-2" /> Add User
        </button>
      </div>
      <div class="overflow-x-auto bg-white rounded-lg shadow">
        <table class="table w-full">
          <thead>
            <tr>
              <th>Username</th>
              <th>Full Name</th>
              <th>Groups</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="user in users" :key="user.id">
              <td>{{ user.username }}</td>
              <td>{{ user.fullName }}</td>
              <td>
                <span v-for="g in user.groups" :key="g" class="badge badge-info mr-1">{{ g }}</span>
              </td>
              <td>
                <button class="btn btn-xs btn-ghost text-tiffany" @click="openUserModal(user)"><TablerIcon name="edit" /></button>
                <button class="btn btn-xs btn-ghost text-red-500" @click="confirmDeleteUser(user)"><TablerIcon name="trash" /></button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Groups Tab -->
    <div v-if="tab === 'groups'">
      <div class="flex justify-end mb-2">
        <button class="btn btn-primary" @click="openGroupModal()">
          <TablerIcon name="users-plus" class="w-5 h-5 mr-2" /> Add Group
        </button>
      </div>
      <div class="overflow-x-auto bg-white rounded-lg shadow">
        <table class="table w-full">
          <thead>
            <tr>
              <th>Group Name</th>
              <th>Members</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="group in groups" :key="group.id">
              <td>{{ group.name }}</td>
              <td>
                <span v-for="u in group.members" :key="u" class="badge badge-info mr-1">{{ u }}</span>
              </td>
              <td>
                <button class="btn btn-xs btn-ghost text-tiffany" @click="openGroupModal(group)"><TablerIcon name="edit" /></button>
                <button class="btn btn-xs btn-ghost text-red-500" @click="confirmDeleteGroup(group)"><TablerIcon name="trash" /></button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- User Modal -->
    <dialog v-if="showUserModal" class="modal modal-open">
      <form method="dialog" class="modal-box" @submit.prevent="saveUser">
        <h3 class="font-bold text-lg mb-4">{{ editingUser ? 'Edit User' : 'Add User' }}</h3>
        <div class="mb-2">
          <label class="label">Username</label>
          <input v-model="userForm.username" class="input input-bordered w-full" required :disabled="editingUser" />
        </div>
        <div class="mb-2">
          <label class="label">Full Name</label>
          <input v-model="userForm.fullName" class="input input-bordered w-full" />
        </div>
        <div class="mb-2">
          <label class="label">Password</label>
          <input v-model="userForm.password" class="input input-bordered w-full" :required="!editingUser" type="password" />
        </div>
        <div class="mb-2">
          <label class="label">Groups</label>
          <select v-model="userForm.groups" class="select select-bordered w-full" multiple>
            <option v-for="g in groups" :key="g.id" :value="g.name">{{ g.name }}</option>
          </select>
        </div>
        <div class="modal-action">
          <button class="btn" @click="closeUserModal" type="button">Cancel</button>
          <button class="btn btn-primary" type="submit">Save</button>
        </div>
      </form>
    </dialog>

    <!-- Group Modal -->
    <dialog v-if="showGroupModal" class="modal modal-open">
      <form method="dialog" class="modal-box" @submit.prevent="saveGroup">
        <h3 class="font-bold text-lg mb-4">{{ editingGroup ? 'Edit Group' : 'Add Group' }}</h3>
        <div class="mb-2">
          <label class="label">Group Name</label>
          <input v-model="groupForm.name" class="input input-bordered w-full" required :disabled="editingGroup" />
        </div>
        <div class="mb-2">
          <label class="label">Members</label>
          <select v-model="groupForm.members" class="select select-bordered w-full" multiple>
            <option v-for="u in users" :key="u.id" :value="u.username">{{ u.username }}</option>
          </select>
        </div>
        <div class="modal-action">
          <button class="btn" @click="closeGroupModal" type="button">Cancel</button>
          <button class="btn btn-primary" type="submit">Save</button>
        </div>
      </form>
    </dialog>

    <!-- Confirm Delete Modal -->
    <dialog v-if="showConfirmDelete" class="modal modal-open">
      <form method="dialog" class="modal-box" @submit.prevent="doDelete">
        <h3 class="font-bold text-lg mb-4">Confirm Delete</h3>
        <p>Are you sure you want to delete this {{ deleteType }}?</p>
        <div class="modal-action">
          <button class="btn" @click="closeConfirmDelete" type="button">Cancel</button>
          <button class="btn btn-error" type="submit">Delete</button>
        </div>
      </form>
    </dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import TablerIcon from '../components/TablerIcon.vue'
import { userApi, groupApi } from '@/services/api'

const tab = ref('users')
const users = ref([])
const groups = ref([])

const showUserModal = ref(false)
const showGroupModal = ref(false)
const showConfirmDelete = ref(false)
const editingUser = ref(null)
const editingGroup = ref(null)
const deleteType = ref('user')
const deleteTarget = ref(null)

const userForm = reactive({ username: '', fullName: '', password: '', groups: [] })
const groupForm = reactive({ name: '', members: [] })

const fetchUsers = async () => {
  users.value = (await userApi.list()).data.users
}
const fetchGroups = async () => {
  groups.value = (await groupApi.list()).data.groups
}

const openUserModal = (user = null) => {
  showUserModal.value = true
  editingUser.value = user
  if (user) {
    userForm.username = user.username
    userForm.fullName = user.fullName
    userForm.password = ''
    userForm.groups = [...user.groups]
  } else {
    userForm.username = ''
    userForm.fullName = ''
    userForm.password = ''
    userForm.groups = []
  }
}
const closeUserModal = () => { showUserModal.value = false }
const saveUser = async () => {
  if (editingUser.value) {
    await userApi.update(userForm.username, userForm)
    window.$toast({ message: 'User updated', type: 'success', icon: 'ti ti-user-check' })
  } else {
    await userApi.create(userForm)
    window.$toast({ message: 'User created', type: 'success', icon: 'ti ti-user-plus' })
  }
  showUserModal.value = false
  fetchUsers()
}
const confirmDeleteUser = (user) => {
  showConfirmDelete.value = true
  deleteType.value = 'user'
  deleteTarget.value = user
}

const openGroupModal = (group = null) => {
  showGroupModal.value = true
  editingGroup.value = group
  if (group) {
    groupForm.name = group.name
    groupForm.members = [...group.members]
  } else {
    groupForm.name = ''
    groupForm.members = []
  }
}
const closeGroupModal = () => { showGroupModal.value = false }
const saveGroup = async () => {
  if (editingGroup.value) {
    await groupApi.update(groupForm.name, groupForm)
    window.$toast({ message: 'Group updated', type: 'success', icon: 'ti ti-users' })
  } else {
    await groupApi.create(groupForm)
    window.$toast({ message: 'Group created', type: 'success', icon: 'ti ti-users-plus' })
  }
  showGroupModal.value = false
  fetchGroups()
}
const confirmDeleteGroup = (group) => {
  showConfirmDelete.value = true
  deleteType.value = 'group'
  deleteTarget.value = group
}

const closeConfirmDelete = () => { showConfirmDelete.value = false }
const doDelete = async () => {
  if (deleteType.value === 'user') {
    await userApi.delete(deleteTarget.value.username)
    window.$toast({ message: 'User deleted', type: 'info', icon: 'ti ti-user-x' })
    // Optionally: show undo snackbar
  } else {
    await groupApi.delete(deleteTarget.value.name)
    window.$toast({ message: 'Group deleted', type: 'info', icon: 'ti ti-users-x' })
    // Optionally: show undo snackbar
  }
  showConfirmDelete.value = false
  fetchUsers()
  fetchGroups()
}

onMounted(() => {
  fetchUsers()
  fetchGroups()
})
</script> 