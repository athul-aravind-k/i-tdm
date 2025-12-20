<script setup>
/* =========================
   Emits
========================= */
const emit = defineEmits(['change'])

/* =========================
   FiveM-safe helper
========================= */
function getResourceName() {
  return window.GetParentResourceName
    ? GetParentResourceName()
    : 'dev'
}

/* =========================
   Actions
========================= */
function joinDM() {
  fetch(`https://${getResourceName()}/get-active-matches`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  })
    .then(res => res.json())
    .then(matches => {
      emit('change', {
        payload: {
          mode: 'deathmatch',
          matches
        }
      })
    })
}

function joinTDM() {
  fetch(`https://${getResourceName()}/get-active-matches-tdm`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  })
    .then(res => res.json())
    .then(matches => {
      emit('change', {
        screen: 'activeTdms',
        payload: {
          mode: 'tdm',
          matches
        }
      })
    })
}
</script>

<template>
  <div class="create-container">
    <!-- Back -->
    <h2 class="close" @click="emit('change','main')">
      &lt; Back
    </h2>

    <!-- TDM JOIN CARD -->
    <div class="card tdm-card">
      <h2 class="card-title">
        Team Death Match
      </h2>

      <button
        id="join-tdm"
        class="card-btn tdm-button"
        @click="joinTDM"
      >
        Select
      </button>

      <img
        class="card-bottom-image create-card-image"
        src="/assets/teamdeathmatch.png"
        alt="Team Death Match"
      />
    </div>

    <!-- DM JOIN CARD -->
    <div class="card death-card">
      <h2 class="card-title">
        Death Match
      </h2>

      <button
        id="join-dm"
        class="card-btn dm-button"
        @click="joinDM"
      >
        Select
      </button>

      <img
        class="card-bottom-image join-card-image"
        src="/assets/deathmatch-card.png"
        alt="Death Match"
      />
    </div>

    <!-- COMING SOON -->
    <div class="card coming-soon-card">
      <h2 class="coming-soon">
        coming soon..
      </h2>
    </div>
  </div>
</template>
