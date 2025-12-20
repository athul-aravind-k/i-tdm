<script setup>
import { ref,watch } from 'vue'

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
   Local State
========================= */
const selectedMap = ref(null)
const maps = ref(null)
const isTdm = props.payload.isTdm

watch(
  () => props.payload,
  (newPayload) => {
    if (!newPayload) return
    maps.value = newPayload.maps
  },
  { immediate: true }
)

/* =========================
  FiveM-safe helper
========================= */
function getResourceName() {
  return window.GetParentResourceName
    ? GetParentResourceName()
    : 'dev'
}

/* =========================
  Confirm selection
========================= */
function confirmSelection() {
  if (!selectedMap.value) return

  // DM
  if (!isTdm) {
    fetch(`https://${getResourceName()}/startDeathMatch`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        selectedMap: selectedMap.value
      })
    })

    emit('change', 'main')
    return
  }

  // TDM → go to password screen
  emit('change', {
    screen: 'tdmPassword',
    payload: { map: selectedMap.value }
  })
}

/* =========================
  Back
========================= */
function goBack() {
  emit('change', 'create')
}
</script>

<template>
  <div class="create-container">
    <!-- Back -->
    <h2 class="close" @click="goBack">
      &lt; Back
    </h2>

    <h2 class="title-text">
      Create a lobby
    </h2>

    <!-- MAP LIST -->
    <div class="map-container">
      <div
        v-for="map in maps"
        :key="map.name"
        class="map"
        :style="`background-image: url(assets/maps/${map.image})`"
      >
        <div
          class="map-name-container"
          :class="{ 'map-name-container-selected': selectedMap === map.name }"
          @click="selectedMap = map.name"
        >
          <span>{{ map.label }}</span>
        </div>
      </div>
    </div>

    <!-- CONFIRM -->
    <button
      class="confirm-dmatch-btn"
      :disabled="!selectedMap"
      @click="confirmSelection"
    >
      Confirm
    </button>
  </div>
</template>
