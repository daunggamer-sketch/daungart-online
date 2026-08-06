// ====== AUDIO SPECTRUM ANIMATION ======
// Generate equalizer bars automatically
const spectrumContainer = document.getElementById('spectrum');
const totalBars = 24;

if (spectrumContainer) {
  for (let i = 0; i < totalBars; i++) {
    const bar = document.createElement('div');
    bar.classList.add('spectrum-bar');
    spectrumContainer.appendChild(bar);
  }

  const bars = document.querySelectorAll('#spectrum .spectrum-bar');

  function animateSpectrum() {
    bars.forEach(bar => {
      const randomHeight = Math.floor(Math.random() * 85) + 15;
      bar.style.height = `${randomHeight}%`;
    });
  }
  setInterval(animateSpectrum, 120);
}

// ====== KNOB ROTATION ON CLICK ======
const knobs = document.querySelectorAll('.audio-knob');
knobs.forEach(knob => {
  let currentRotation = 0;
  // honor any inline starting rotation
  const indicator = knob.querySelector('.knob-indicator');
  if (indicator && indicator.style.transform) {
    const match = indicator.style.transform.match(/rotate\((\d+)deg\)/);
    if (match) currentRotation = parseInt(match[1], 10) % 360;
  }
  knob.addEventListener('click', () => {
    currentRotation = (currentRotation + 45) % 360;
    if (indicator) indicator.style.transform = `rotate(${currentRotation}deg)`;
  });
});

// ====== ESTIMATE CALCULATOR (existing) ======
function calculateEstimate() {
  const checks = document.querySelectorAll('#estimateForm input[type="checkbox"]:checked');
  let total = 0;
  checks.forEach(input => total += Number(input.value));
  const formatter = new Intl.NumberFormat('id-ID');
  document.getElementById('estimateValue').textContent = total > 0 ? 'Rp' + formatter.format(total) : 'Rp0';
}
