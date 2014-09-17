function(doc) {
  if(doc.type === 'dk_ag' && doc.application_id) {
    emit([doc.application_id], null);
  }
}
