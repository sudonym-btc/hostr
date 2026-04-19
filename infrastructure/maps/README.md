# Google Maps Cloud Styles

Google's current public APIs do not create cloud map styles or map IDs end-to-end. Create these once in the Google Cloud Console, then keep the resulting platform map IDs in Terraform as `google_maps_web_map_id`, `google_maps_android_map_id`, and `google_maps_ios_map_id`.

1. Open Google Maps Platform Map Styles in the target project.
2. Create a light style and import `hostr-light-map-style.json`.
3. Create a dark style and import `hostr-dark-map-style.json`.
4. Publish both styles.
5. Open Map Management and create the needed JavaScript, Android, and iOS map IDs.
6. Associate the light style with light mode and the dark style with dark mode on each platform map ID.
7. Set the `google_maps_*_map_id` values in the environment tfvars file, run `scripts/deploy.sh <env>`, then regenerate Dart env constants.

The app passes the platform-specific map ID with an explicit `MapColorScheme`
matching the active Flutter theme. If a platform map ID is empty, the app falls
back to the generated local JSON style for that platform.

Sources:

- https://developers.google.com/maps/documentation/javascript/map-rendering-type
- https://developers.google.com/maps/documentation/javascript/cloud-customization/map-styles
- https://developers.google.com/maps/documentation/javascript/cloud-customization/modes-and-types
- https://developers.google.com/maps/documentation/mapmanagement/overview
