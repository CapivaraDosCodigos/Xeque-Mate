@tool
extends SubViewportContainer
class_name TextureSave

enum Formato { PNG, JPG, WEBP, EXR, DDS }
const EXTENSAO: Dictionary[Formato, String] = {
	Formato.JPG: ".jpg",
	Formato.WEBP: ".webp",
	Formato.EXR: ".exr",
	Formato.DDS: ".dds"
	}

@export_tool_button("Salvar", "Add") var salvar: Callable = exportar_textura

@export_dir var pasta_saida: String = "res://exports"
@export var nome_arquivo: String = "textura_exportada"
@export var formato: Formato = Formato.PNG
@export var importar_no_editor: bool = true

@export_group("Qualidade")
@export_range(0.0, 1.0, 0.01) var qualidade_jpg: float = 0.9
@export_range(0.0, 1.0, 0.01) var qualidade_webp: float = 0.9
@export var webp_sem_perda: bool = false
## JPG não tem transparência: as áreas transparentes recebem esta cor.
@export var jpg_cor_fundo: Color = Color.WHITE
@export var exr_escala_cinza: bool = false

@export_category("Ferramentas")
@export_tool_button("Definir Size", "FixedSize") var update_size: Callable = update_new_size

var viewport: SubViewport:
	get():
		if not is_instance_valid(viewport):
			viewport = null

			for node: Node in get_children():
				if node is SubViewport:
					viewport = node
					break

		return viewport


func update_new_size() -> void:
	if not is_instance_valid(viewport):
		return

	var new_size: Vector2i = _find_content_size()

	if new_size == Vector2i.ZERO or new_size == viewport.size:
		return

	var undo_redo: Object = Engine.get_singleton("EditorInterface").get_editor_undo_redo()

	undo_redo.create_action("Atualizar tamanho do viewport")
	undo_redo.add_do_property(viewport, &"size", new_size)
	undo_redo.add_undo_property(viewport, &"size", viewport.size)
	undo_redo.commit_action()


func _find_content_size() -> Vector2i:
	var result: Vector2i = Vector2i.ZERO

	for child: Node in viewport.get_children():
		if child is TextureRect:
			return Vector2i((child as TextureRect).size)

		if child is Sprite2D:
			var sprite: Sprite2D = child as Sprite2D

			if is_instance_valid(sprite.texture):
				result = Vector2i(sprite.texture.get_size())

	return result


func exportar_textura() -> void:
	if viewport == null:
		push_error("Nenhum SubViewport encontrado como filho.")
		return

	# Espera renderizar
	await RenderingServer.frame_post_draw

	var imagem: Image = viewport.get_texture().get_image()

	if imagem == null or imagem.is_empty():
		push_error("Falha ao capturar imagem.")
		return

	# Garante diretório
	var pasta: String = ProjectSettings.localize_path(pasta_saida)

	if not DirAccess.dir_exists_absolute(pasta):
		var erro_dir: Error = DirAccess.make_dir_recursive_absolute(pasta)

		if erro_dir != OK:
			push_error("Não foi possível criar a pasta '%s': %s" % [pasta, error_string(erro_dir)])
			return

	var caminho: String = pasta.path_join(_gerar_nome() + _get_extensao())
	var erro: Error = _salvar_imagem(imagem, caminho)

	if erro != OK:
		push_error("Falha ao salvar '%s': %s" % [caminho, error_string(erro)])
		return

	print("Textura salva em: ", caminho)

	if importar_no_editor:
		_importar_no_editor(caminho)


func _gerar_nome() -> String:
	var nome: String = nome_arquivo.strip_edges().validate_filename()

	if not nome.is_empty():
		return nome

	var data: Dictionary = Time.get_datetime_dict_from_system()

	return "export_%04d-%02d-%02d_%02d-%02d-%02d" % [
		data.year, data.month, data.day,
		data.hour, data.minute, data.second,
	]


func _get_extensao() -> String:
	if EXTENSAO.has(formato):
		return EXTENSAO[formato]
	return ".png"


func _salvar_imagem(imagem: Image, caminho: String) -> Error:
	match formato:
		Formato.JPG:
			return _preparar_para_jpg(imagem).save_jpg(caminho, qualidade_jpg)

		Formato.WEBP:
			# save_webp(caminho, lossy, qualidade): lossy = true usa a qualidade
			return imagem.save_webp(caminho, not webp_sem_perda, qualidade_webp)

		Formato.EXR:
			return imagem.save_exr(caminho, exr_escala_cinza)

		Formato.DDS:
			return imagem.save_dds(caminho)

		_:
			return imagem.save_png(caminho)


func _preparar_para_jpg(imagem: Image) -> Image:
	# JPG não suporta alpha: compõe sobre uma cor de fundo
	imagem.convert(Image.FORMAT_RGBA8)

	var fundo: Image = Image.create_empty(imagem.get_width(), imagem.get_height(), false, Image.FORMAT_RGBA8)
	fundo.fill(jpg_cor_fundo)
	fundo.blend_rect(imagem, Rect2i(Vector2i.ZERO, imagem.get_size()), Vector2i.ZERO)
	fundo.convert(Image.FORMAT_RGB8)

	return fundo


func _importar_no_editor(caminho: String) -> void:
	# Só funciona no editor e dentro de res://
	if not Engine.is_editor_hint() or not caminho.begins_with("res://"):
		push_warning("Importação automática ignorada (fora do editor ou da pasta do projeto).")
		return

	# Singleton via Engine para o script não quebrar em builds exportadas
	var editor: Object = Engine.get_singleton("EditorInterface")
	var fs: EditorFileSystem = editor.get_resource_filesystem()

	if fs.get_file_type(caminho).is_empty():
		# Arquivo novo: o scan detecta e importa automaticamente
		fs.scan()
	else:
		# Arquivo sobrescrito: atualiza e reimporta
		fs.update_file(caminho)
		fs.reimport_files(PackedStringArray([caminho]))
