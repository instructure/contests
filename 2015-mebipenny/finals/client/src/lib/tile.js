export const SIZE = 128;

function image(file) {
  return new Promise(resolve => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.src = file;
  });
}

const promiseKeys = {
  I: image(require('../assets/I.png')),
  J: image(require('../assets/J.png')),
  L: image(require('../assets/L.png')),
  O: image(require('../assets/O.png')),
  S: image(require('../assets/S.png')),
  T: image(require('../assets/T.png')),
  Z: image(require('../assets/Z.png'))
};

export const images = {};

const promises = Object.keys(promiseKeys).map(key => promiseKeys[key]);
export const imagesLoaded = Promise.all(promises).then(imgs => {
  const keys = Object.keys(promiseKeys);
  for (let i = 0, l = imgs.length; i < l; ++i) {
    images[keys[i]] = imgs[i];
  }
});

export function drawTo (context, key, x, y) {
  if (!images[key]) {
    return false;
  }
  context.drawImage(images[key], x * SIZE, y * SIZE);
}
