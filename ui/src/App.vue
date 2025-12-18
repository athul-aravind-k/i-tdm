<script setup>
import { ref, computed, onMounted } from 'vue'

import MainMenu from './screens/MainMenu.vue'
import CreateMenu from './screens/CreateMenu.vue'
import JoinMenu from './screens/JoinMenu.vue'
import MapSelect from './screens/MapSelect.vue'
import TdmJoin from './screens/TdmJoin.vue'
import TdmPassword from './screens/TdmPassword.vue'
import ActiveMatches from './screens/ActiveMatches.vue'

import Hud from './components/Hud.vue'
import Toasts from './components/Toasts.vue'

const uiVisible = ref(false)
const screen = ref('main')
const payload = ref(null)

function getResourceName() {
  return window.GetParentResourceName
    ? GetParentResourceName()
    : 'dev'
}

function changeScreen(event) {
  if (typeof event === 'string') {
    screen.value = event
    payload.value = null
  } else {
    screen.value = event.screen
    payload.value = event.payload ?? null
  }
}

function closeUI() {
  uiVisible.value = false
  screen.value = 'main'
  payload.value = null

  fetch(`https://${getResourceName()}/close`, {
    method: 'POST'
  })
}

onMounted(() => {
  window.addEventListener('message', (event) => {
    const data = event.data

    switch (data.type) {
      case 'open-ui':
        uiVisible.value = true
        screen.value = 'main'
        break

      case 'show-tdm-join':
        screen.value = 'tdmJoin'
        payload.value = {
          map: data.map,
          matchId: data.matchId,
          playerId: data.playerId,
          mapTable: data.mapTable
        }
        break

      case 'show-active-matches':
        screen.value = 'activeMatches'
        payload.value = data.matches
        break
    }
  })

  window.addEventListener('keydown', (e) => {
    console.log(JSON.stringify(e))
    if (e.key === 'Escape') closeUI()
  })
})

const currentComponent = computed(() => {
  return {
    main: MainMenu,
    create: CreateMenu,
    join: JoinMenu,
    map: MapSelect,
    tdmJoin: TdmJoin,
    tdmPassword: TdmPassword,
    activeMatches: ActiveMatches
  }[screen.value]
})
</script>

<template>
  <!-- MAIN UI -->
  <div v-if="uiVisible" @keyup.esc="closeUI" class="popup">
    <component
      :is="currentComponent"
      :payload="payload"
      @change="changeScreen"
      @close="closeUI"
    />
  </div>

  <!-- GLOBAL OVERLAYS -->
  <Toasts />
  <Hud />
</template>
