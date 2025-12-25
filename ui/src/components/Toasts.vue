<script setup>
import { ref, onMounted } from 'vue'

const toasts = ref([])
let counter = 0

function addToast({ killer, killed, type }) {
  const id = counter++

  toasts.value.push({
    id,
    killer,
    killed,
    type
  })

  // Remove after 5 seconds
  setTimeout(() => {
    toasts.value = toasts.value.filter(t => t.id !== id)
  }, 5000)
}

onMounted(() => {
  window.addEventListener('message', (event) => {
    if (event.data.type === 'kill-msg' || event.data.type ==='kill-msg-tdm' ) {
      addToast(event.data.message)
    }
  })
})
</script>

<template>
  <div id="toast-container">
    <div
      v-for="toast in toasts"
      :key="toast.id"
      class="toast"
      :class="{
        'toast-kill': toast.type === 'killed',
        'toast-killed': toast.type === 'dead',
        'toast-other': toast.type === 'other'
      }"
    >
      <span class="killer-name">
        {{ toast.killer }}
      </span>

      <img
        class="bullet-msg"
        src="/assets/bullet.png"
        alt="kill"
      />

      <span class="victim-name">
        {{ toast.killed }}
      </span>
    </div>
  </div>
</template>
