<script setup>
/*
  Props / emits
*/
const emit = defineEmits(['change'])

/*
  FiveM-safe fetch helper
*/
function getResourceName() {
  return window.GetParentResourceName
    ? GetParentResourceName()
    : 'dev'
}

/*
  Actions
*/
function createDM() {
  fetch(`https://${getResourceName()}/get-maps`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ isTdm: false })
  })
    .then(res => res.json())
    .then(maps => {
      emit('change', {
        screen: 'map',
        payload: { maps, isTdm: false }
      })
    })
}

function createTDM() {
  fetch(`https://${getResourceName()}/get-maps`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ isTdm: true })
  })
    .then(res => res.json())
    .then(maps => {
      emit('change', {
        screen: 'map',
        payload: { maps, isTdm: true }
      })
    })
}
</script>

<template>
  <div class="create-container">
    <!-- Back -->
    <h2 class="close" @click="emit('change', 'main')">
      &lt; Back
    </h2>

    <!-- TDM CARD -->
    <div class="card tdm-card">
      <h2 class="card-title">Team Death Match</h2>

      <button
        class="card-btn tdm-button"
        @click="createTDM"
      >
        Select
      </button>

      <img
        class="card-bottom-image create-card-image"
        src="/assets/teamdeathmatch.png"
        alt=""
      />
    </div>

    <!-- DM CARD -->
    <div class="card death-card">
      <h2 class="card-title">Death Match</h2>

      <button
        class="card-btn dm-button"
        @click="createDM"
      >
        Select
      </button>

      <img
        class="card-bottom-image join-card-image"
        src="/assets/deathmatch-card.png"
        alt=""
      />
    </div>

    <!-- COMING SOON -->
    <div class="card coming-soon-card">
      <h2 class="coming-soon">coming soon..</h2>
    </div>
  </div>
</template>
