<script setup>
import { ref, computed, watch } from 'vue'

/* =========================
   Props / Emits
========================= */
const props = defineProps({
  payload: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['change'])

/* =========================
   LOCAL REACTIVE STATE
========================= */
const map = ref(null)
const matchId = ref(null)
const playerId = ref(null)
const match = ref(null)

/* =========================
   Derived State
========================= */
const isOwner = computed(() => {
  return match.value && playerId.value === match.value.creatorId
})

/* =========================
   Watch payload changes
========================= */
watch(
  () => props.payload,
  (newPayload) => {
    if (!newPayload) return

    map.value = newPayload.map
    matchId.value = newPayload.matchId
    playerId.value = newPayload.playerId
    match.value = newPayload.mapTable
    console.log(JSON.stringify(match.value))
  },
  { immediate: true }
)

/* =========================
   FiveM-safe helper
========================= */
function getResourceName() {
  return typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : null
}

/* =========================
   Actions
========================= */
function joinTeam(team) {
  if (!match.value) return

  fetch(`https://${getResourceName()}/join-tdm`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: map.value,
      matchId: String(matchId.value),
      bucketId: match.value.bucketId,
      team
    })
  })
}

function kickPlayer(team, id) {
  if (!isOwner.value) return

  fetch(`https://${getResourceName()}/kick-tdm-player`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: map.value,
      matchId: matchId.value,
      team,
      playerId: id
    })
  })
}

function updateWeapon(value) {
  fetch(`https://${getResourceName()}/tdm-update-settings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: map.value,
      matchId: matchId.value,
      weapon: value
    })
  })
}

function updateTime(value) {
  fetch(`https://${getResourceName()}/tdm-update-settings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: map.value,
      matchId: matchId.value,
      time: Number(value)
    })
  })
}

function startMatch() {
  if (!isOwner.value) return

  fetch(`https://${getResourceName()}/start-tdm`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: map.value,
      matchId: matchId.value,
      bucketId: match.value.bucketId
    })
  })

  emit('change', 'main')
}

function goBack() {
  emit('change', 'create')
}
</script>

<template>
  <div v-if="match" class="create-container">
    <!-- BACK -->
    <h2 class="close" @click="goBack">
      &lt; Back
    </h2>

    <!-- BLUE TEAM -->
    <div class="card-tdm-team tdm-join-card-blue">
      <h2 class="card-title-tdm">Blue</h2>

      <div class="tdm-player-list tdm-player-list-blue">
        <div
          v-for="player in Object.values(match.blueTeam || {})"
          :key="player.source"
          class="tdm-player-item tdm-player-item-blue"
          :class="{ 'tdm-owner': isOwner }"
        >
          <img
            v-if="isOwner"
            class="tdm-owner-player"
            src="/assets/crown.png"
          />

          <span>{{ player.name }}</span>

          <img
            v-if="isOwner && player.source !== match.creatorId"
            class="tdm-delete-player"
            src="/assets/delete.png"
            @click="kickPlayer('blue', player.source)"
          />
        </div>
      </div>

      <button
        class="tdm-team-join-button tdm-blue-btn"
        @click="joinTeam('blue')"
      >
        Join
      </button>
    </div>

    <!-- RED TEAM -->
    <div class="card-tdm-team tdm-join-card-red">
      <h2 class="card-title-tdm">Red</h2>

      <div class="tdm-player-list tdm-player-list-red">
        <div
          v-for="player in Object.values(match.redTeam || {})"
          :key="player.source"
          class="tdm-player-item tdm-player-item-red"
          :class="{ 'tdm-owner': isOwner }"
        >
          <img
            v-if="isOwner"
            class="tdm-owner-player"
            src="/assets/crown.png"
          />

          <span>{{ player.name }}</span>

          <img
            v-if="isOwner && player.source !== match.creatorId"
            class="tdm-delete-player"
            src="/assets/delete.png"
            @click="kickPlayer('red', player.source)"
          />
        </div>
      </div>

      <button
        class="tdm-team-join-button tdm-red-btn"
        @click="joinTeam('red')"
      >
        Join
      </button>
    </div>

    <!-- SETTINGS -->
    <div v-if="isOwner" class="card-tdm-team-right">
      <h2 class="card-title-tdm">Settings</h2>

      <select class="tdm-select" :value="match.time" @change="updateTime($event.target.value)">
        <option value="5">5 Min</option>
        <option value="10">10 Min</option>
        <option value="15">15 Min</option>
        <option value="20">20 Min</option>
        <option value="30">30 Min</option>
      </select>

      <select class="tdm-select" :value="match.weapon" @change="updateWeapon($event.target.value)">
        <option value="assault">Assault</option>
        <option value="pistol">Pistol</option>
      </select>

      <button class="tdm-team-join-button tdm-start-btn" @click="startMatch">
        Start
      </button>
    </div>
  </div>
</template>
