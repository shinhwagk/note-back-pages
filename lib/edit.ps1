. "lib/git.ps1"
function add_label($path, $label) {
  $file = $path + ".json"
  $notes = Get-Content $file | ConvertFrom-Json
  $notes.labels += $label
  $notes | ConvertTo-Json -Compress | Out-File $file

  $new_dir = $path + "/" + $label
  if (-Not(Test-Path $new_dir)) { New-Item -ItemType Directory $new_dir }
  
  $new_file = $path + "/" + $label + ".json"

  @{labels=@(); categorys=@()} | ConvertTo-Json -Compress | Out-File $new_file

  git_commit("add label: ${label}")
}

function remove_label($path, $idx) {
  $file = $path + ".json"
  $notes = Get-Content $file | ConvertFrom-Json

  $label = $notes.labels[$idx]

  $notes.labels = $notes.labels | Where-Object { $_ -ne $label }

  if (-Not $notes.labels) { $notes.labels = @() }

  ConvertTo-Json -Compress $notes | Out-File $file

  Remove-Item -Path ($path + '/' + $label)
  Remove-Item -Path ($path + '/' + $label + ".json")
  git_commit("delete label: ${label}")
}

function rename_label($path, $idx, $new_label) {
  $file = $path + ".json"
  $notes = Get-Content $file | ConvertFrom-Json
  $old_label = $notes.labels[$idx]

  $notes.labels = $notes.labels, $new_label
  $notes.labels = @($notes.labels | Where-Object { $_ -ne $old_label })

  ConvertTo-Json -Compress $notes | Out-File $file

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
    # ConvertTo-Json -Compress $note | Write-Host
    ConvertTo-Json -Depth 5 -Compress $noteback | Out-File $file
  }
}

function remove_category($path, $category) {
  $file = $path + ".json"
  $note = Get-Content $file | ConvertFrom-Json
  $note.categorys.psobject.Properties.Remove($category)
  ConvertTo-Json -Compress $note | Out-File $file
}

function rename_category($path, $old_category) {
  $file = $path + ".json"

  $note = Get-Content $file | ConvertFrom-Json

  $new_category = Read-Host "enter new category"

  $category_content = $note.categorys | Select-Object -ExpandProperty $old_category

  $note.categorys | Add-Member -NotePropertyName $new_category -NotePropertyValue @($category_content)

  $note.categorys.psobject.Properties.Remove($old_category)

  ConvertTo-Json -Compress $note | Out-File $file

  git_commit("rename category: $old_category -> $new_category")
}

function add_note($path, $idx) {
  $file = $path + ".json"
  $path >> ".tmp/path"; $idx >> ".tmp/category"
  
  $noteback = Get-Content $file | ConvertFrom-Json;
  $data_num = $noteback.categorys[$idx].cols
  foreach ($n in (1 .. $data_num)) {
    if ( -Not (Test-Path ".tmp/${n}")) { Out-File ".tmp/${n}" } 
    else { Write-Host "./tmp is no empty." }
  }

  Write-Host "data file folder at './tmp'"
  $doc = Read-Host "write doc [y/n]?"
  $file = Read-Host "write file [y/n]?"

  $id = [int](Get-Content "id"); ($id + 1) | Out-File "id"

  $id >> ".tmp/id"
  if ($doc -eq 'y') { New-Item ".tmp/doc" -ItemType Directory; New-Item ".tmp/README.md" -ItemType File; }

  if ($file -eq 'y') { New-Item ".tmp/file" -ItemType Directory }
 
  # if ($code -eq 'y'){
  #   $datas = [string]@()
  #   foreach ($n in (1 .. $data_num)){
  #     $datas += [IO.File]::ReadAllText(".tmp/${n}")
  #   }
    
  #   $obj = @{id=$id;data=$datas;doc=$false;file=$false}

  #   $noteback.categorys[$idx].notes = @($noteback.categorys[$idx].notes,$obj)
  #   ConvertTo-Json $noteback -Compress -Depth 4 | Out-File $file
  # }
}

function launch_note() {
  $path = Get-Content ".tmp/path" | Out-String
  [int]$id = Get-Content ".tmp/id" | Out-String
  [int]$c_idx = Get-Content ".tmp/category" | Out-String
  
  if (Test-Path ".tmp/file") { Move-Item -Path ".tmp/doc" -Destination "data-docs/${id}" }
  if (Test-Path ".tmp/doc") { Move-Item -Path ".tmp/file" -Destination "data-files/${id}" }

    #   $datas = [string]@()
  #   foreach ($n in (1 .. $data_num)){
  #     $datas += [IO.File]::ReadAllText(".tmp/${n}")
  #   }
    
  #   $obj = @{id=$id;data=$datas;doc=$false;file=$false}

  #   $noteback.categorys[$idx].notes = @($noteback.categorys[$idx].notes,$obj)
  #   ConvertTo-Json $noteback -Compress -Depth 4 | Out-File $file

}

function update_note() {

}

