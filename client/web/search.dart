import 'dart:html';
import 'dart:html' as html;
import 'package:web_ui/web_ui.dart';
import 'package:api_doc/ast.dart';
import 'package:api_doc/model.dart';

@observable
class Search extends WebComponent {
  /** Search query. */
  String searchQuery = "";
  List<SearchResult> results = <SearchResult>[];
  bool isFocused = false;

  int _pendingSearchHandle;
  bool _pendingSubmit = false;

  bool get inProgress => _pendingSearchHandle != null;

  void created() {
    super.created();

    watch(() => searchQuery, (_) {
      if (_pendingSearchHandle != null) {
        window.clearTimeout(_pendingSearchHandle);
      }
      _pendingSearchHandle = window.setTimeout(() {
        _pendingSearchHandle = null;
        results = lookupSearchResults(searchQuery, 30);
        if (_pendingSubmit) {
          onSubmitCallback();
          _pendingSubmit = false;
        }
      }, 50);
    });
  }

  void onBlurCallback(_) {
    // Sadly we have to wait a few msec as the active element switches to the
    // body and then the correct active element rather than switching directly
    // to the correct element.
    window.setTimeout(() {
      window.console.log(document.activeElement.tagName);
      if (document.activeElement == null ||
          !this.contains(document.activeElement)) {
        isFocused = false;
      }
    }, 50);
  }

  void onFocusCallback(_) {
    isFocused = true;
  }

  void onSubmitCallback() {
    if (_pendingSearchHandle != null) {
      _pendingSubmit = true;
      // Submit will be triggered after a search result is returned.
      return;
    }
    if (!results.isEmpty) {
      String refId;
      if (this.contains(document.activeElement)) {
        refId = document.activeElement.dataAttributes['ref-id'];
      }
      if (refId == null || refId.isEmpty) {
        // If nothing is focused, use the first search result.
        refId = results.first.element.refId;
      }
      navigateTo(refId);
      searchQuery = "";
    }
  }

  void inserted() {
    super.inserted();
    html.Element.focusEvent.forTarget(xtag, useCapture: true)
        .listen(onFocusCallback);
    html.Element.blurEvent.forTarget(xtag, useCapture: true)
        .listen(onBlurCallback);
    onKeyPress.listen(onKeyPressCallback);
  }

  void onKeyPressCallback(KeyboardEvent e) {
    if (e.keyCode == 13) {
      onSubmitCallback();
      e.preventDefault();
    }
  }
}