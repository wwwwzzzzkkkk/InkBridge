import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { wantConstant } from '@kit.AbilityKit';
import { RoundTripBridge } from '../roundtrip/RoundTripBridge';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleIncomingWant(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleIncomingWant(want);
  }

  private handleIncomingWant(want: Want): void {
    this.handleSharedPDF(want);
    const action = want.parameters?.liveViewAction;
    if (typeof action === 'string') {
      RoundTripBridge.submitLiveViewAction(action);
    }
  }

  private handleSharedPDF(want: Want): void {
    let uri = want.uri ?? '';
    if (!uri && want.parameters) {
      const stream = want.parameters[wantConstant.Params.PARAMS_STREAM];
      if (typeof stream === 'string') {
        uri = stream;
      } else if (Array.isArray(stream) && stream.length > 0 && typeof stream[0] === 'string') {
        uri = stream[0] as string;
      }
    }
    if (uri && (want.type === 'application/pdf' || uri.toLowerCase().includes('.pdf'))) {
      RoundTripBridge.submit(uri);
    }
  }

  private loadMainPage(windowStage: window.WindowStage): void {
    try {
      windowStage.loadContent('pages/Index');
    } catch (_) {}
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      const mainWindow = windowStage.getMainWindowSync();
      Promise.all([
        mainWindow.setWindowLayoutFullScreen(true),
        mainWindow.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          navigationBarColor: '#00000000',
          isStatusBarLightIcon: false,
          isNavigationBarLightIcon: false,
          statusBarContentColor: '#1a2230',
          navigationBarContentColor: '#384252'
        })
      ]).finally(() => this.loadMainPage(windowStage));
    } catch (_) {
      this.loadMainPage(windowStage);
    }
  }
}
