# App icon

Replace `app_icon.png` with your new icon, then regenerate platform assets:

```bash
dart run flutter_launcher_icons
```

Requirements:

- **1024×1024** PNG (square)
- **No transparency** on iOS (solid background; `remove_alpha_ios` is enabled in `pubspec.yaml`)
- Simple, recognizable shape — it will be shown very small on the home screen

After regenerating, do a full restart on the simulator (not just hot reload) to see the new icon.
