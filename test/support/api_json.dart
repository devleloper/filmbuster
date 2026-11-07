/// One source as the API sends it.
Map<String, dynamic> movieSourceJson({
  String id = 'openmovies.sintel-1080p',
  String kind = 'direct',
  String url = 'https://download.blender.org/durian/movies/Sintel.mp4',
  String? sourcePageUrl = 'https://durian.blender.org/',
  String licenseUrl = 'https://creativecommons.org/licenses/by/3.0/',
}) => {
  'id': id,
  'provider': 'openmovies',
  'providerName': 'Open movies',
  'kind': kind,
  'url': url,
  'quality': '1080p',
  'sizeBytes': 1180090590,
  'mimeType': 'video/mp4',
  'codecs': 'avc1.640028, mp4a.40.2',
  'license': {
    'spdxId': 'CC-BY-3.0',
    'name': 'Creative Commons Attribution 3.0',
    'url': licenseUrl,
  },
  'attribution': '© copyright Blender Foundation | durian.blender.org',
  'sourcePageUrl': sourcePageUrl,
};

Map<String, dynamic> trailerJson({
  String url = 'https://www.youtube.com/watch?v=abc_123',
}) => {
  'name': 'Official Trailer',
  'site': 'YouTube',
  'key': 'abc_123',
  'url': url,
  'type': 'Trailer',
  'publishedAt': '2010-09-30T00:00:00Z',
};
