import { reactive } from 'vue'

export const notificationStore = reactive({
  current: null,

  show(type, message) {
    this.current = {
      type,
      message,
      id: Date.now()
    }
  },

  clear() {
    this.current = null
  }
})
