var selectedMap = null;

$(function () {
  window.addEventListener("message", function (event) {
    if (event.data.type == "open-ui") {
      openUi(true);
    }
    if (event.data.type == "kill-msg") {
      showKillToast(event.data.message);
    }
    if (event.data.type == "update-stats") {
      updateHud(event.data.message);
    }
    if (event.data.type == "toggle-hud") {
      const data = event.data.message;
      toggleHud(data.bool, data.time, data.totalTime);
    }
  });
});

function openUi(bool) {
  if (bool) {
    $(".popup").css("display", "block");
    $(".card-container").css("display", "flex");
    setTimeout(function () {
      $(".popup").css("opacity", 1);
    }, 100);
    $("body").css("background-color", "rgba(0, 0, 0, 0.61)");
  } else {
    $(".create-container").empty();
    $(".card-container").css("display", "none");
    $(".popup").css("display", "none");
    $(".create-container").css("display", "none");
    $("body").css("background-color", "rgba(0, 0, 0, 0)");
    setTimeout(function () {
      $(".popup").css("opacity", 0);
    }, 100);
    $.post("https://i-tdm/close");
  }
  selectedMap = null;
}

function setupCreateMatchScreen(maps, isTdm) {
  if (isTdm) {
    console.log("TDM");
  } else {
    showMaps(maps);
  }
}

$(document).on("click", "#create-btn", function (e) {
  showCreateOptions();
});

$(document).on("click", "#join-btn", function (e) {
  showJoinOptions();
});

$(document).on("click", "#leader-board-btn", function (e) {
  //click leaderboard
});

$(document).on("click", "#back-btn-mode", function (e) {
  $(".create-container").css("display", "none");
  $(".card-container").css("display", "flex");
});

$(document).on("click", "#back-btn-join", function (e) {
  $(".create-container").css("display", "none");
  $(".create-container").empty();
  $(".card-container").css("display", "flex");
});

$(document).on("click", "#join-tdm", function (e) {
  // show TDM maps
  //change hardcode
  $.post(
    "https://i-tdm/join-tdm",
    JSON.stringify({ map: "map1" }),
    function (data) {
      // load hud here
    }
  );
});

$(document).on("click", "#create-dm", function (e) {
  $.post(
    "https://i-tdm/get-maps",
    JSON.stringify({ isTdm: false }),
    function (data) {
      setupCreateMatchScreen(data, false);
    }
  );
});

$(document).on("click", "#create-tdm", function (e) {
  $.post(
    "https://i-tdm/get-maps",
    JSON.stringify({ isTdm: true }),
    function (data) {
      // setupCreateMatchScreen(data.maps, true);
    }
  );
});

$(document).on("keydown", function () {
  if (event.keyCode == 27) {
    //esc button
    openUi(false);
  }
});

$(document).on("click", ".map-name-container", function (e) {
  $(".map-name-container").removeClass("map-name-container-selected");
  $(this).addClass("map-name-container-selected");
  var map = $(this).attr("data-name");
  selectedMap = map;
});

$(document).on("click", "#back-btn-select-map", function (e) {
  $(".create-container").empty();
  selectedMap = null;
  showCreateOptions();
});

$(document).on("click", "#confirm-dm-selection", function (e) {
  if (selectedMap) {
    $.post(
      "https://i-tdm/startDeathMatch",
      JSON.stringify({ selectedMap }),
      function (data) {
        openUi(false);
      }
    );
  }
});

$(document).on("click", "#join-dm", function (e) {
  $.post("https://i-tdm/get-active-matches", {}, function (matches) {
    showActiveMatches(matches);
  });
});

$(document).on("click", ".match-select-btn", function (e) {
  var map = $(this).attr("data-map");
  var matchId = $(this).attr("data-matchId");
  var bucketId = $(this).attr("data-bucketId");
  openUi(false);
  $.post(
    "https://i-tdm/join-dm",
    JSON.stringify({ map: map, matchId: String(matchId), bucketId: bucketId }),
    function (data) {
      if (data) {
      }
    }
  );
});

$(document).on("click", "#back-btn-select-match", function (e) {
  $(".create-container").empty();
  showJoinOptions();
});

function showKillToast(data) {
  const killer = data.killer;
  const killed = data.killed;
  const type = data.type;
  showToast(killer, killed, type);
}
var counter = 0;
function showToast(killer, victim, type) {
  var toast = document.createElement("div");
  toast.classList.add("toast");
  if (type == "killed") {
    toast.classList.add("toast-kill");
  } else if (type == "dead") {
    toast.classList.add("toast-killed");
  } else if (type == "other") {
    toast.classList.add("toast-other");
  }
  var toastId = "toast-div-" + counter;
  toast.id = toastId;
  message = `<span class="killer-name"> ${killer + "  "}</span>
    <img class="bullet-msg" src="assets/bullet.png" />
    <span class="victim-name">${"  " + victim}</span>`;
  toast.innerHTML = message;

  // Append the new div to the container
  var container = document.getElementById("toast-container");
  container.appendChild(toast);

  // Set a timer to hide the div after 5 seconds
  setTimeout(function () {
    var toastToRemove = document.getElementById(toastId);
    if (toastToRemove) {
      container.removeChild(toastToRemove);
    }
  }, 5000);

  counter++;
}

function toggleHud(bool, time, totalTime) {
  if (bool) {
    $(".progress-bars").css("display", "flex");
    $(".kd-numbers").css("display", "block");
    toggleTimer(true, time, totalTime);
  } else {
    $(".progress-bars").css("display", "none");
    $(".kd-numbers").css("display", "none");
    $(".timer-container").css("display", "none");
    toggleTimer(false, 0, 0);
  }
}

function updateHud(data) {
  const hpPer = (data.hp / 200) * 100;
  const armor = data.armor;

  if (hpPer <= 10) {
    $("#health-bar").removeClass("health-orange");
    $("#health-bar").removeClass("health-yellow");
    $("#health-bar").removeClass("health-light-yellow");
    $("#health-bar").removeClass("health-green");
    $("#health-bar").addClass("health-red");
  } else if (hpPer <= 25) {
    $("#health-bar").removeClass("health-red");
    $("#health-bar").removeClass("health-yellow");
    $("#health-bar").removeClass("health-light-yellow");
    $("#health-bar").removeClass("health-green");
    $("#health-bar").addClass("health-orange");
  } else if (hpPer <= 50) {
    $("#health-bar").removeClass("health-red");
    $("#health-bar").removeClass("health-light-yellow");
    $("#health-bar").removeClass("health-green");
    $("#health-bar").removeClass("health-orange");
    $("#health-bar").addClass("health-yellow");
  } else if (hpPer <= 75) {
    $("#health-bar").removeClass("health-red");
    $("#health-bar").removeClass("health-green");
    $("#health-bar").removeClass("health-orange");
    $("#health-bar").removeClass("health-yellow");
    $("#health-bar").addClass("health-light-yellow");
  } else {
    $("#health-bar").removeClass("health-red");
    $("#health-bar").removeClass("health-orange");
    $("#health-bar").removeClass("health-yellow");
    $("#health-bar").removeClass("health-light-yellow");
    $("#health-bar").addClass("health-green");
  }

  $(".armor-progress").css("width", armor + "%");
  $(".health-progress").css("width", hpPer + "%");
  $("#health-count").html(
    `<img class="stats-img" src="assets/hp.png" alt=""> ${hpPer}`
  );
  $("#armor-count").html(
    `<img class="stats-img" src="assets/armor.png" alt=""> ${armor}`
  );
  const clip = (data.clip < 10 ? "0" : "") + data.clip;
  $("#clip-ammo").html(clip);
  $("#clip-ammo").html(data.clip);
  $("#total-ammo").html(data.ammo);
  $("#death-count").html(data.deaths);
  $("#kill-count").html(data.kills);
}

var x = null;

function toggleTimer(bool, time, totalTime) {
  if (bool) {
    $(".timer-container").css("display", "flex");
    var timer = new Date().getTime() + time;
    function updateTimer() {
      var now = new Date().getTime();
      var t = timer - now;
      var perc = Math.round((t / totalTime) * 100);
      var minutes = Math.floor((t % (1000 * 60 * 60)) / (1000 * 60));
      var seconds = Math.floor((t % (1000 * 60)) / 1000);
      const timeMsg = minutes + " : " + (seconds < 10 ? "0" : "") + seconds;
      $("#timer").html(timeMsg);
      if (t <= 30000) {
        $(".timer-inner").css(
          "background",
          "conic-gradient(#FF0000 " +
            perc +
            "%, rgba(255, 255, 255, 0) " +
            perc +
            "%)"
        );
        $("#timer").css("color", "red");
      } else if (t <= 120000) {
        $(".timer-inner").css(
          "background",
          "conic-gradient(#FF6B00 " +
            perc +
            "%, rgba(255, 255, 255, 0) " +
            perc +
            "%)"
        );
      } else if (t <= 180000) {
        $(".timer-inner").css(
          "background",
          "conic-gradient(#EBFF00 " +
            perc +
            "%, rgba(255, 255, 255, 0) " +
            perc +
            "%)"
        );
      } else {
        $(".timer-inner").css(
          "background",
          "conic-gradient(#00ff47 " +
            perc +
            "%, rgba(255, 255, 255, 0) " +
            perc +
            "%)"
        );
      }
      if (t <= 0) {
        clearInterval(x);
        $("#timer").html("00 : 00");
        $("#timer").css("color", "white");
        $(".timer-inner").css(
          "background",
          "conic-gradient(#FF6B00 0%, 0, rgba(255, 255, 255, 0))"
        );
      } else {
        clearTimeout(x);
        x = setTimeout(updateTimer, 1000);
      }
    }
    if (x !== null) {
      clearTimeout(x);
    }
    updateTimer();
  } else {
    $(".timer-container").css("display", "none");
    $("#timer").html("00 : 00");
    $("#timer").css("color", "white");
    clearTimeout(x);
    x = null;
  }
}

function showMaps(maps) {
  var container = `<h2 class="title-text">Create a lobby</h2>
  <h2 id="back-btn-select-map" class="close"> < Back</h2>
  <div class="map-container">`;
  if (maps.length) {
    for (i = 0; i <= maps.length - 1; i++) {
      var map = `<div class="map" style="background-image: url(assets/maps/${maps[i].image});">
      <div class="map-name-container" data-name="${maps[i].name}"><span>${maps[i].label}</span></div>
    </div>`;
      container += map;
    }
  }
  container += `<button id="confirm-dm-selection" class="confirm-dmatch-btn">Confirm</button></div>`;
  $(".create-container").empty();
  $(".create-container").append(container);
  $(".create-container").css("display", "flex");
  $(".card-container").css("display", "none");
}

function showCreateOptions() {
  var cardsHTML = `
  <h2 id="back-btn-join" class="close">< Back</h2>
    <div class="card tdm-card">
      <h2 class="card-title">Team Death Match</h2>
      <button id="create-tdm" class="card-btn tdm-button">Select</button>
      <img class="card-bottom-image create-card-image" src="assets/teamdeathmatch.png" alt="" />
    </div>
    <div class="card death-card">
      <h2 class="card-title">Death Match</h2>
      <button id="create-dm" class="card-btn dm-button">Select</button>
      <img class="card-bottom-image join-card-image" src="assets/deathmatch-card.png" alt="" />
    </div>
    <div class="card coming-soon-card">
      <h2 class="coming-soon">coming soon..</h2>
    </div>
  `;
  $(".create-container").append(cardsHTML);
  $(".create-container").css("display", "flex");
  $(".card-container").css("display", "none");
}

function showJoinOptions() {
  var cardsHTML = `
  <h2 id="back-btn-join" class="close">< Back</h2>
    <div class="card tdm-card">
      <h2 class="card-title">Team Death Match</h2>
      <button id="join-tdm" class="card-btn tdm-button">Select</button>
      <img class="card-bottom-image create-card-image" src="assets/teamdeathmatch.png" alt="" />
    </div>
    <div class="card death-card">
      <h2 class="card-title">Death Match</h2>
      <button id="join-dm" class="card-btn dm-button">Select</button>
      <img class="card-bottom-image join-card-image" src="assets/deathmatch-card.png" alt="" />
    </div>
    <div class="card coming-soon-card">
      <h2 class="coming-soon">coming soon..</h2>
    </div>
  `;
  $(".create-container").append(cardsHTML);
  $(".create-container").css("display", "flex");
  $(".card-container").css("display", "none");
}

function showActiveMatches(matches) {
  var container = `<h2 id="back-btn-select-match" class="close">< Back</h2>
  <h2 class="title-text">Active lobbies</h2>`;
  if (matches.length) {
    container += `<div class="match-container">`;
    for (i = 0; i <= matches.length - 1; i++) {
      var timer = new Date().getTime() + matches[i].timeLeft;
      var now = new Date().getTime();
      var t = timer - now;
      var minutes = Math.floor((t % (1000 * 60 * 60)) / (1000 * 60));
      var seconds = Math.floor((t % (1000 * 60)) / 1000);
      var timeLeft = minutes + " : " + seconds;
      var truncatedCreator = matches[i].creator.substring(0, 12);
      var memberCount = matches[i].members + "/" + matches[i].maxMembers;
      var dynamicMatch = `
      <div class="match">
        <div class="match-items">
          <div class="match-contents"><img src="assets/loc-pin.svg" alt=""><span class="match-map match-text">${matches[i].mapLabel}</span></div>
          <div class="match-contents"><img src="assets/crown.svg" alt=""><span class="creator-name match-text">${truncatedCreator}</span></div>
          <div class="match-contents"><img src="assets/clock-match.svg" alt=""><span class="match-time  match-text">${timeLeft}</span></div>
          <div class="match-contents"><img src="assets/members.svg" alt=""><span class="match-members  match-text">${memberCount}</span></div>
          <div class="match-contents match-btn-container"><button class="match-select-btn" data-map="${matches[i].map}" data-matchId="${matches[i].matchId}" data-bucketId="${matches[i].bucketId}">Join</button></div>
        </div>
      </div> `;
      container += dynamicMatch;
    }
    container += `</div>`;
  } else {
    container += `<div class="no-match">No Active Matches Found</div>`;
  }
  $(".create-container").empty();
  $(".create-container").append(container);
  $(".create-container").css("display", "flex");
  $(".card-container").css("display", "none");
}
