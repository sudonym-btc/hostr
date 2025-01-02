String convertToTitleCase(String snakeCase) {
  return snakeCase.split('_').map((word) {
    return word[0].toUpperCase() + word.substring(1);
  }).join(' ');
}
