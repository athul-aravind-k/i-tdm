<script setup>
import { ref, computed, onMounted, watch } from 'vue'

import MainMenu from './screens/MainMenu.vue'
import CreateMenu from './screens/CreateMenu.vue'
import JoinMenu from './screens/JoinMenu.vue'
import MapSelect from './screens/MapSelect.vue'
import TdmJoin from './screens/TdmJoin.vue'
import TdmPassword from './screens/TdmPassword.vue'
import ActiveTdms from './screens/ActiveTdms.vue'

import Hud from './components/Hud.vue'
import Toasts from './components/Toasts.vue'
import Leaderboard from './screens/Leaderboard.vue'
import ZoneWarning from './screens/ZoneWarning.vue'
import UIToast from './components/UIToast.vue'
import { notificationStore } from './components/uiNotificationStore'
import MatchEndScreen from './screens/MatchEndScreen.vue'

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

watch(uiVisible, (isOpen) => {
  if (isOpen) {
    document.body.style.backgroundColor = 'rgba(0, 0, 0, 0.61)'
  } else {
    document.body.style.backgroundColor = 'transparent'
  }
})

onMounted(() => {
  window.addEventListener('message', (event) => {
    const data = event.data

    switch (data.type) {
      case 'open-ui':
        uiVisible.value = true
        screen.value = 'main'
        break
      case 'close-ui':
        uiVisible.value = false
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
        uiVisible.value = true
        break

      case 'show-active-matches':
        screen.value = 'activeMatches'
        payload.value = data.matches
        break
      case 'show-active-matches-tdm':
        screen.value = 'activeTdms'
        payload.value = {
          mode: 'tdm',
          matches: data.matches
        }
        break
      case 'matchend':
        payload.value = data
        uiVisible.value = true
        screen.value = 'matchend'
        break
        case 'notify':
        notificationStore.show(data.action, data.message);
        break
    }
  })

  window.addEventListener('keydown', (e) => {
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
    activeMatches: ActiveTdms,
    activeTdms: ActiveTdms,
    leaderboard: Leaderboard,
    matchend: MatchEndScreen 
  }[screen.value]
})
</script>

<template>
  <!-- MAIN UI -->
  <div 
    v-if="uiVisible" 
    @keyup.esc="closeUI" 
    class="popup"
    :style="(currentComponent === Leaderboard || currentComponent === MatchEndScreen) ? { height: '100%', width: '100%', overflowY: 'auto' } : {}"
  >
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
  <ZoneWarning/>
  <UIToast
    :notification="notificationStore.current"
    @close="notificationStore.clear()"
  />
</template>
