function(doc) {
  if(doc.type === 'dk_app') {
    emit([doc.user_id], null);
  }
}
