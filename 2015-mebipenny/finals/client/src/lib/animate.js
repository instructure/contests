let nextFrameCallbacks = [];
let looping = false;

function loop() {
  const callbacks = nextFrameCallbacks;
  nextFrameCallbacks = [];
  looping = true;
  let cb;
  while ((cb = callbacks.shift())) {
    cb();
  }
  if (nextFrameCallbacks.length > 0) {
    window.requestAnimationFrame(loop);
  } else {
    looping = false;
  }
}

function requestSharedAnimationFrame(cb) {
  nextFrameCallbacks.push(cb);
  if (!looping) {
    window.requestAnimationFrame(loop);
  }
}

export default function animate(start, end, duration, easingFn, fn) {
  const diff = end - start;
  return new Promise(resolve => {
    const startTime = Date.now();
    const handleFrame = () => {
      const curTime = Date.now() - startTime;
      fn(curTime >= duration ? end : easingFn(curTime, start, diff, duration));
      if (curTime < duration) {
        requestSharedAnimationFrame(handleFrame);
      } else {
        resolve();
      }
    };
    requestSharedAnimationFrame(handleFrame);
  });
}
