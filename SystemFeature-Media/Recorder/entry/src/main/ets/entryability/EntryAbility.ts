/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIAbility from '@ohos.app.ability.UIAbility';
import Window from '@ohos.window';
import promptAction from '@ohos.promptAction';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import Logger from '../model/Logger';
import type { Permissions } from '@ohos.abilityAccessCtrl';

const TAG: string = '[Index]';
const PERMISSIONS: Array<Permissions> = ['ohos.permission.MICROPHONE', 'ohos.permission.WRITE_MEDIA',
  'ohos.permission.READ_MEDIA', 'ohos.permission.WRITE_AUDIO', 'ohos.permission.WRITE_AUDIO'];

export default class EntryAbility extends UIAbility {
  async onCreate(want, launchParam) {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let authResults = await atManager.requestPermissionsFromUser(this.context, PERMISSIONS);
    if (authResults.authResults.includes(-1)) {
      return;
    }
  }

  onDestroy() {
    Logger.info(TAG, `Ability onDestroy`)
  }

  async onWindowStageCreate(windowStage: Window.WindowStage): Promise<void> {
    // Main window is created, set main page for this ability
    Logger.info(TAG, 'Ability onWindowStageCreate');
    promptAction.showToast({
      message: 'requestPermissionsFromUser success'
    });
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        Logger.error(TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return
      }
      Logger.info(TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    })
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    Logger.info(TAG, 'Ability onWindowStageDestroy')
  }

  onForeground() {
    // Ability has brought to foreground
    Logger.info(TAG, 'Ability onForeground')
  }

  onBackground() {
    // Ability has back to background
    Logger.info(TAG, 'Ability onBackground')
  }
}
