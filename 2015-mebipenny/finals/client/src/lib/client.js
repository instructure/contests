import faye from 'faye';
const client = new faye.Client(`${process.env.PANDA_PUSH_BASE_URL}/push`);
export default client;
