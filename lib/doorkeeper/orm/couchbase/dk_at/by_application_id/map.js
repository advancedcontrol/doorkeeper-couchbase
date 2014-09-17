function(doc) {
  if(doc.type === 'dk_at' && doc.application_id) {
    emit([doc.application_id], null);
  }
}
