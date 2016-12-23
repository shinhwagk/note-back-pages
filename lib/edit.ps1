. "lib/git.ps1"
. "lib/common.ps1"

function add_label($path, $label) {
  $noteback = getNoteBack $path
  $noteback.labels += $label
  saveNoteBack $noteback $path

  $child_path = $path + "/" + $label
  if (-Not(Test-Path $child_path)) { New-Item -ItemType Directory $child_path }
  saveNoteBack @{labels=@(); categorys=@()} $child_path
  git_commit("create label: ${label}")
}

function remove_label($path, $idx) {
  $noteback = getNoteBack $path

  $label = $noteback.labels[$idx]

  $noteback.labels = $noteback.labels | Where-Object { $_ -ne $label }

  if (-Not $noteback.labels) { $noteback.labels = @() }

  saveNoteBack $noteback $path

  Remove-Item -Path ($path + '/' + $label)
  Remove-Item -Path ($path + '/' + $label + ".json")
  
  git_commit("delete label: ${label}")
}

function rename_label($path, $idx, $new_label) {
  $notes = getNoteBack $path
  $old_label = $notes.labels[$idx]

  $notes.labels = $notes.labels, $new_label
  $notes.labels = @($notes.labels | Where-Object { $_ -ne $old_label })

  saveNoteBack $notes $path

  $old_dir = $path + '/' + $old_label
  $old_file = $path + '/' + $old_label + ".json"
  $new_file = $new_label + ".json"

  Rename-Item -Path $old_dir -NewName $new_label
  Rename-Item -Path $old_file -NewName $new_file

  git_commit("rename label: $old_label -> $new_label")
}

function add_category($path, $c_name, $c_cols) {
  $file = $path + ".json"

  if ($c_name.length -ge 1 -and $c_cols -ge 1) {
    $noteback = Get-Content $file | ConvertFrom-Json
    $noteback.categorys += @{name=$c_name;cols=$c_cols;notes=@()}
    ConvertTo-Json -Depth 5 -Compress $noteback | Out-File $file -Encoding utf8
  }
}

function remove_category($path, $idx) {
  $notes = getNoteBack $path

  $categorys = [System.Collections.ArrayList]$notes.categorys
  $categorys.RemoveAt($idx)

  $notes.categorys = @($categorys)

  saveNoteBack $notes $path
}

function rename_category($path, $idx, $c_name) {
  $note = getNoteBack $path

  $category = $note.categorys[$idx]

  $note.categorys[$idx].name = $c_name

  saveNoteBack $note $path

  git_commit("rename category: $old_category -> $new_category")
}

function create_note_template($path, $idx) {
  $dir_cnt = Get-ChildItem ".tmp" | Measure-Object | ForEach-Object {$_.Count}

  $create_template = $false

  if ($dir_cnt -ge 1) {
    Write-Host ".tmp below file exists" -ForegroundColor Red
    $del? = Read-Host "IsDelete? [y/n]"
    if ($del? -eq "y") {
      Remove-Item -Path ".tmp" -Recurse;
      New-Item -Path ".tmp" -ItemType Directory | Out-Null;
      $create_template = $true
    }
  } else {
    $create_template = $true
  }
  if ($create_template) {
    $id = [int](Get-Content "id"); ($id + 1) | Out-File "id" -Encoding utf8
    New-Item -Path ".tmp/${id}" -ItemType Directory | Out-Null;
    $file = $path + ".json"
    $path >> ".tmp/path"; $idx > ".tmp/category"
    
    $noteback = Get-Content $file | ConvertFrom-Json;
    $data_num = $noteback.categorys[$idx].cols

    foreach ($n in (1 .. $data_num)) {
      if ( -Not (Test-Path ".tmp/${id}/${n}")) { Out-File ".tmp/${id}/${n}" }
      else { Write-Host "./tmp/${id} is no empty." }
    }

    Write-Host "data file folder at './tmp/${id}'"
    $doc = Read-Host "write doc [y/n]?"
    $file = Read-Host "write file [y/n]?"

    if ($doc -eq 'y') { New-Item ".tmp/${id}/doc" -ItemType Directory | Out-Null; New-Item ".tmp/${id}/README.md" -ItemType File | Out-Null;; }
    if ($file -eq 'y') { New-Item ".tmp/${id}/file" -ItemType Directory | Out-Null; }
    Write-Host "note template create success." -ForegroundColor Yellow
  }
}

function launch_note() {
  [int]$c_idx = Get-Content ".tmp/category" | Out-String
  $id = Get-ChildItem -Path ".tmp" -Directory | Select-Object -First 1 -ExpandProperty "Name"
  $doc = Test-Path ".tmp/${id}/doc" 
  $file = Test-Path ".tmp/${id}/file"
  $note = @{id=$id;doc=$doc;file=$file}
  
  $path = Get-Content ".tmp/path"
  $file = $path + ".json"

  $noteback = Get-Content $file | ConvertFrom-Json
  $noteback.categorys[$c_idx].notes += $note
  ConvertTo-Json $noteback -Compress -Depth 4 | Out-File $file -Encoding utf8
  # Move-Item -Path ".tmp/${id}" -Destination $path
  Get-ChildItem "./tmp" | Remove-Item
}

function remove_note($path, $c_idx, $n_id) {
  $file = $path + ".json"
  $noteback = Get-Content $file | ConvertFrom-Json
  $new_notes = @($noteback.categorys[$c_idx].notes | Where-Object { $_.id -ne $n_id })
  $noteback.categorys[$c_idx].notes = $new_notes
  # ConvertTo-Json $noteback.categorys[$c_idx].notes | Write-Host
  ConvertTo-Json $noteback -Compress -Depth 4 | Out-File $file -Encoding utf8
}
