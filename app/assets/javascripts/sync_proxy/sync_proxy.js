import $ from 'jquery';

export default class GLSyncProxy {
  constructor(options = {}) {
    this.container = document.querySelector(options.selector);
debugger
    this.setSocketUrl();
    debugger
    this.createTerminal();
  }

  setSocketUrl() {
    const { protocol, hostname, port } = window.location;
    const wsProtocol = protocol === 'https:' ? 'wss://' : 'ws://';
    const path = this.container.dataset.projectPath;

    this.socketUrl = `${wsProtocol}${hostname}:${port}${path}`;
  }

  createTerminal() {


    // this.terminal = new Terminal(this.options);
debugger
    this.socket = new WebSocket(this.socketUrl, ['terminal.gitlab.com']);
    this.socket.binaryType = 'arraybuffer';

    this.socket.onopen = () => {
      this.runProxy();
    };
    this.socket.onerror = () => {
      console.log("Sync Connection Shutdown");
    };
  }

  runProxy() {
    const decoder = new TextDecoder('utf-8');
    const encoder = new TextEncoder('utf-8');

    // this.terminal.on('data', data => {
    //   this.socket.send(encoder.encode(data));
    // });

    socket.send(encoder.encode('Hello Server!'));

    this.socket.addEventListener('message', ev => {
      this.terminal.write(decoder.decode(ev.data));
    });
  }
}
