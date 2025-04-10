///|
let install_cmd : @mug.Command = @mug.Command::new(
  (
    "install", "Install a specific version of Node.js. If version is \"lts\", the latest LTS version will be installed.",
    install_action,
  ),
)

///|
fn install_action(c : @mug.Command, args : @mug.TArgs) -> Unit {
  let base_url = "https://nodejs.org/dist"
  let list = @util.fetch_list?().or([])
  let version = match args[0] {
    "lts" => {
      let latest_lts = list
        .iter()
        .find_first(fn {
          item =>
            match item.lts.as_string() {
              None => false
              Some(_) => true
            }
        })
        .unwrap()
      let version = @util.normalize_version(latest_lts.version)
      println("Latest LTS version is \{version}")
      version
    }
    "latest" => {
      let latest_lts = list[0]
      let version = @util.normalize_version(latest_lts.version)
      println("Latest version is \{version}")
      version
    }
    str => @util.normalize_version(str)
  }
  if version.is_empty() {
    println("Error fetching available versions.")
    return
  }
  if @util.is_version_installed(version) {
    println("Node.js \{version} is already installed.")
    return
  }

  // TODO: 获取系统
  let tarball_name = @util.format_node_tarball(
    version~,
    os_tag="darwin",
    cpu_arch=@util.get_arch(),
  )
  let url = "\{base_url}/\{version}/\{tarball_name}"
  let dir = "\{@util.get_version_dir()}/\{version}"
  println("Downloading \{tarball_name}...")
  let is_downloaded = @util.download_file(url, dir)
  if not(is_downloaded) {
    println("Error downloading Node.js \{version}.")
    return
  }
  println("Node.js \{version} installed successfully.")
}
