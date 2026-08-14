# PowerManager MVP-A 阶段 18：能量球 Shader 升级实现与模拟器验收记录

## 0. 文档状态

- 日期：2026-08-12
- 对应 Spec：`GitHub类似案例调研与Stage18能量球Shader升级_Spec_v1.md`
- 验收设备：Pixel_7 模拟器 / Android 14 / API 34 / 1080 × 2400 / 420 dpi
- Flutter：3.44.8 stable / Dart 3.12.2
- 渲染后端：Impeller / OpenGLES
- 状态：Stage18-0～18-5 已完成模拟器验收
- 真机状态：按既有决定延后至整个 MVP-B 完成后统一验收

---

# 1. 实施结果

## 1.1 组件边界

原本集中在 `home_page.dart` 中的 `_EnergyBall` 和 `_EnergyBallPainter` 已拆分为独立模块：

- `energy_orb.dart`：Widget、动画控制、生命周期与信息层；
- `energy_orb_parameters.dart`：纯显示参数派生；
- `energy_orb_shader_renderer.dart`：Program 缓存、uniform 映射与 Shader Painter；
- `energy_orb_fallback_painter.dart`：原 Canvas 方案的正式兜底；
- `shaders/energy_orb.frag`：Impeller 兼容的能量球 Fragment Shader。

首页只传入估计值、初始值、点亮状态和晨间状态，不向渲染组件传入数据库、provider 或活动用例。

## 1.2 Shader 视觉

新 Shader 实现：

- 圆形距离场蒙版、柔化边缘和约 1.65 倍外光晕；
- 三个继承 HTML 运动相位的大尺度融合场；
- 两层轻量 value noise 形成连续坐标扭曲；
- 主色、辅色和深色基底的逐像素混合；
- 未点亮、充足、平静、中低、低和透支六种状态；
- 透支时 45% 薄雾、较低噪声密度和灰紫语义；
- 现有九段 `EnergyPalette` 继续作为唯一色温来源。

视觉结果不再表现为三枚轮廓清楚的规则径向渐变圆，内部颜色边界形成连续融合，同时仍保持
稳定完整的圆球轮廓。

## 1.3 动效与生命周期

- 正常呼吸：约 5.5 秒 / ±1.8%；
- 透支呼吸：约 8 秒 / ±0.8%；
- 流速：按精力比例从 1.00 连续降至 0.35；
- 晨间点亮：800ms activation progress；
- 估计变化：520ms 单次余波，最大约 3%；
- 减少动态效果：时间相位、流动、呼吸和余波全部稳定冻结；
- App 离开前台：停止 flow、activation 和 pulse controller；
- App 恢复：从当前动画进度继续，不补播离屏帧。

## 1.4 降级策略

- `FragmentProgram` 只加载并缓存一次；
- Program 加载期间继续显示 Painter，不出现空白加载态；
- Program 加载失败时保留 Painter；
- Shader 绘制异常时当前 Painter 固定切换为 fallback；
- fallback 仍显示颜色、光晕、呼吸、数值和透支标签；
- Shader 与 fallback 均被 `IgnorePointer` 包裹，不干扰上层径向手势。

## 1.5 调试状态画廊

新增仅 Debug 构建可访问的 `/debug/energy-orb` 路由，固定展示：

1. 未点亮；
2. 充足 80%；
3. 平静 50%；
4. 中低 25%；
5. 低 0%；
6. 估计透支 -20。

画廊使用固定直径和固定时间相位，可重复进行视觉对照；Release 构建不会开放该路由。

---

# 2. 自动化验收

## 2.1 基线

修改前：

```text
flutter analyze
0 issue

flutter test
164 tests passed
```

## 2.2 最终结果

```text
dart format
通过

flutter analyze
通过，0 issue

flutter test
通过，183 tests

flutter build apk --debug
通过，Shader 成功编译进入 Android APK

flutter build apk --release --split-per-abi --build-number=6007
通过，生成 armeabi-v7a / arm64-v8a / x86_64 三个 Release APK
```

新增测试覆盖：

- `1.20 / 1.00 / 0.80 / 0.65 / 0.50 / 0.37 / 0.25 / 0.12 / 0.00 /
  -0.10 / -0.30` 色温参数；
- `initialEstimate == 0` 有限值保护；
- 未点亮低速灰暗状态；
- 透支薄雾、流速和浅呼吸；
- 减少动态效果冻结；
- 余波最大约 3%；
- fallback 数字、晨间标签、透支标签与 Semantics；
- 200% 字体；
- 六态调试画廊路由；
- 原有点击与径向记录全量回归。

---

# 3. Pixel_7 模拟器验收

## 3.1 首页

Release x86_64 APK 已覆盖安装到既有 Pixel_7 模拟器，未卸载应用、未清除数据库。

确认：

- 首页能量球中心和尺寸未变化；
- 未晨间确认时保持灰暗状态；
- 数字、晨间上下文、初始估计、`+` 和下方内容位置稳定；
- 调试画廊构建结束后已恢复并安装正常首页 Release；
- 应用无 Shader、Flutter 或 Android Runtime 崩溃日志；
- 后台返回首页正常，没有白屏或重放完整动画。

尝试使用 Android `gfxinfo` 读取 30 秒静止首页帧统计时，Flutter/Impeller Surface 没有向该接口
返回可用帧样本（`Total frames rendered: 0`）。因此没有把无效的 0 帧结果包装成性能结论；本轮
只确认连续运行、切后台和恢复没有肉眼可见的持续卡顿，正式帧时间仍留到 MVP-B 后的真机
DevTools / Perfetto 验收。

## 3.2 六态画廊

截图：`stage18_energy_orb_gallery.png`

确认：

| 状态 | 结果 |
|---|---|
| 未点亮 | 冷灰暗、低对比，数值信息可读 |
| 充足 80% | 青绿主色、光晕最足、内部连续融合 |
| 平静 50% | 天青与青绿色温正确，层次可辨 |
| 中低 25% | 琥珀与天青混合，无红色报警感 |
| 低 0% | 暖橙与褐色正确，球体没有缩小或熄灭 |
| 估计透支 | 低饱和灰紫、薄雾感、负值和文字标签完整 |

共同结果：

- 无矩形裁切、透明背景错误、黑球、白闪或中心偏移；
- 球体边缘稳定，内部颜色区域连续融合；
- 中央数字在六种状态下均可读；
- 未出现红色、爆条、粒子爆炸或封顶暗示；
- Shader 正常运行于 Impeller / OpenGLES，没有触发 fallback 日志。

## 3.3 手势回归

自动化继续通过：

- 200ms 激活；
- 大类、子类和时长均需 500ms 稳定停留才进入下一层；
- 20 次快速掠过不确认；
- 滞回和 ready 状态；
- 三层完整选择后才允许写入；
- 中途取消、超时和不完整松手不写入；
- 所有大类、子类和时长可达。

Shader 绘制层不参与命中测试。根据 2026-08-12 后续体验反馈，仅将 Stage17-D
的三层停留确认由 300ms 提高到 500ms，其余手势参数保持不变。

---

# 4. 验收中的异常与处置

Pixel_7 冷启动时曾出现一次 Android “System UI isn't responding”。检查确认：

- 异常属于模拟器 System UI，而非 PowerManager；
- 恢复系统界面并重启应用后可正常显示；
- PowerManager 日志中没有 FATAL EXCEPTION 或 ANR；
- 后续 Debug 画廊和 Release 首页均正常运行。

模拟器中原应用版本号为 6004，高于仓库默认版本号 1。为保护既有模拟器数据，本轮使用临时
构建号 6005～6007 覆盖安装，没有卸载应用或清空数据。仓库的正式版本号未因此修改。

---

# 5. 未在本阶段验证

根据用户既有决定，以下内容统一延后至 MVP-B 完成后的真机验收：

- Android 真机 60fps 与 jank 数据；
- 持续运行的耗电、温升和后台恢复；
- OLED 屏幕上的灰紫、暖橙和光晕表现；
- 手指遮挡下的流体视觉；
- 20 次真实手势任务的 18/20 成功标准；
- 不同 Android GPU / 驱动的 Shader 兼容性。

当前 Painter fallback 已降低 Shader 兼容性异常对核心使用的影响，但不能替代上述真机验证。

---

# 6. 结论

Stage18 已按 Spec 完成能量球 Shader 结构与流体质感升级，并通过自动化、Android 构建和
Pixel_7 模拟器验收。业务算法、数据结构、首页信息结构和 Stage17-D 手势逻辑均保持不变。

下一阶段不应继续堆叠视觉特效。建议恢复日常自用观察，在真实数据积累期间记录以下反馈：

- 各色温状态是否过亮或过暗；
- 连续观察时流速是否仍显得机械；
- 数值变化余波是否明显但不打扰；
- 透支薄雾态是否仍有足够辨识度。

这些反馈在 MVP-B 完成后的真机专项中统一调参。
