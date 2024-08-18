/*
 * Copyright (C) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIAbility from '@ohos.app.ability.UIAbility';
import type window from '@ohos.window';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import type { Permissions } from '@ohos.abilityAccessCtrl';
import Logger from '../utils/Logger';

/**
 * Lift cycle management of Ability.
 */
export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    Logger.info('testTag', 'Ability onCreate');
    let permissionNames: Array<Permissions> = ['ohos.permission.MEDIA_LOCATION', 'ohos.permission.READ_MEDIA',
      'ohos.permission.WRITE_MEDIA', 'ohos.permission.CAMERA', 'ohos.permission.MICROPHONE'];
    globalThis.abilityWant = this.launchWant;
    globalThis.abilityContext = this.context;
    let atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(globalThis.abilityContext, permissionNames).then((data) => {
      Logger.info('testTag', 'requestPermissionsFromUser called');
    });
    AppStorage.SetOrCreate('context', this.context);
  }

  onDestroy() {
    Logger.info('testTag', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // Main window is created, set main page for this ability
    Logger.info('testTag', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/ListPage', (err, data) => {
      if (err.code) {
        Logger.error('testTag', 'Failed to load the content. Cause: ' + JSON.stringify(err));
        return;
      }
      Logger.info('testTag', 'Succeeded in loading the content. Data: ' + JSON.stringify(data));
    });
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    Logger.info('testTag', 'Ability onWindowStageDestroy');
  }

  onForeground() {
    // Ability has brought to foreground
    Logger.info('testTag', 'Ability onForeground');
  }

  onBackground() {
    // Ability has back to background
    Logger.info('testTag', 'Ability onBackground');
  }
}